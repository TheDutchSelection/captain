#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/etcd_helper"

iptables_default_rules_start="*filter

:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

-A INPUT -i lo -j ACCEPT
-A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
-A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
-A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT

# Allow docker forwarding
-A FORWARD -i docker0 -o eth0 -j ACCEPT
-A FORWARD -i docker0 -o eth1 -j ACCEPT
-A FORWARD -i eth0 -o docker0 -j ACCEPT
-A FORWARD -i eth1 -o docker0 -j ACCEPT

# Accept Pings
-A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Accept any established connections
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Accept SSH
-A INPUT -p tcp --dport 22 -j ACCEPT

# Accept everything from trusted sources
# Gerard Meijer Home
# -A INPUT -p tcp -s 83.128.169.124 -j ACCEPT
# Martijn van Leeuwen Home
# -A INPUT -p tcp -s 83.80.182.202 -j ACCEPT
# Websend Ziggo
# -A INPUT -p tcp -s 213.124.35.208/29 -j ACCEPT
# Websend Xs4all
# -A INPUT -p tcp -s 80.101.112.131 -j ACCEPT"

iptables_default_rules_end="
# Log and drop everything else
-A INPUT -j LOG
-A INPUT -j DROP

COMMIT
"

get_file_path_including_file_name () {
  echo "$FILE_PATH$FILE_NAME"
}

write_iptables_rules_file () {
  set -e
  mkdir -p $FILE_PATH
  cat /dev/null > "$(get_file_path_including_file_name)"

  # get all public ips from all zones
  local etcd_tree=$(get_tree "$ETCD_BASE_PATH")
  local public_ips="$(echo $etcd_tree | $dir/jq '.node.nodes[] as $av_zones | $av_zones.nodes[] | select(.key | contains("/hosts")) | .nodes[] as $hosts | $hosts.nodes[] as $keys | $keys | select(.key | contains("/public_ip")) | .value')"
  # get private ips from this zone
  if [[ ! -z "$ETCD_CURRENT_AVZONE_PATH" ]]; then
    local etcd_tree=$(get_tree "$ETCD_CURRENT_AVZONE_PATH")
    local private_ips="$(echo $etcd_tree | $dir/jq '.node.nodes[] as $hosts | $hosts.nodes[] as $keys | $keys | select(.key | contains("/private_ip")) | .value')"
  fi
  
  # public ip rules
  local public_ip_rules=""
  while read -r public_ip; do
    # remove all double quotes
    public_ip=${public_ip//\"/}
    local public_ip_rule="-A INPUT -p tcp -s $public_ip -j ACCEPT"$'\n'
    local public_ip_rules="$public_ip_rules$public_ip_rule"
  done <<< "$public_ips"

  # private ip rules
  local private_ip_rules=""
  while read -r private_ip; do
    # remove all double quotes
    private_ip=${private_ip//\"/}
    local private_ip_rule="-A INPUT -p tcp -s $private_ip -j ACCEPT"$'\n'
    local private_ip_rules="$private_ip_rules$private_ip_rule"
  done <<< "$private_ips"
  
  # extra rules
  envs="$(env)"
  local extra_rules=""
  while read -r env; do
    if [[ $env == *"IPTABLES_RULE_"* ]]; then
      local extra_rule="$(echo $env | awk -F'=' '{print $2}')"
      local extra_rule="$extra_rule"$'\n'
      local extra_rules="$extra_rules$extra_rule"
    fi
  done <<< "$envs"

  echo "$iptables_default_rules_start" >> "$(get_file_path_including_file_name)"
  echo "# public ip lines" >> "$(get_file_path_including_file_name)"
  echo "$public_ip_rules" >> "$(get_file_path_including_file_name)"
  echo "# private ip lines" >> "$(get_file_path_including_file_name)"
  echo "$private_ip_rules" >> "$(get_file_path_including_file_name)"
  echo "# extra lines" >> "$(get_file_path_including_file_name)"
  echo "$extra_rules" >> "$(get_file_path_including_file_name)"
  echo "$iptables_default_rules_end" >> "$(get_file_path_including_file_name)"
}

watch_iptables_rules_file () {
  local end_loop=false
  local current_file="$(get_file_path_including_file_name)"
  current_rules="$(/usr/bin/stat -c%s $current_file)"
  while [[ "$end_loop" != true ]]; do
    FILE_NAME="iptable_rules_watch"
    write_iptables_rules_file
    local new_file="$(get_file_path_including_file_name)"
    new_rules="$(/usr/bin/stat -c%s $new_file)"
    if [[ "$current_rules" != "$new_rules" && "$new_rules" != "0" ]]; then
      end_loop=true
    fi
    sleep "$REFRESH_TIME"
  done
}

if [[ "$MODE" == "init" ]]; then
  echo "writing iptables rules file at $(get_file_path_including_file_name)..."
  write_iptables_rules_file
else
  echo "watching changes for iptables rules file at $(get_file_path_including_file_name)..."
  watch_iptables_rules_file
fi