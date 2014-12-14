#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

read -r -d '' iptables_default_rules_start << EOM || true
*filter

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
EOM

read -r -d '' iptables_default_rules_end << EOM || true
# Log and drop everything else
-A INPUT -j LOG
-A INPUT -j DROP

COMMIT
EOM

write_iptables_rules_file () {
  set -e
  mkdir -p $FILE_PATH
  cat /dev/null > "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"

  # get all public ips from all zones
  local etcd_tree="$(get_tree $ETCD_BASE_PATH)"
  local public_ips="$(echo $etcd_tree | $dir/jq '.node.nodes[] as $av_zones | $av_zones.nodes[] | select(.key | contains("/hosts")) | .nodes[] as $hosts | $hosts.nodes[] as $keys | $keys | select(.key | contains("/public_ip")) | .value')"
  # get private ips from this zone
  if [[ ! -z "$ETCD_CURRENT_AVZONE_PATH" ]]; then
    local etcd_tree="$(get_tree $ETCD_CURRENT_AVZONE_PATH)"
    local private_ips="$(echo $etcd_tree | $dir/jq '.node.nodes[] as $hosts | $hosts.nodes[] as $keys | $keys | select(.key | contains("/private_ip")) | .value')"
  fi
  
  # public ip rules
  local public_ip_rules=""
  while read -r public_ip; do
    if [[ ! -z "$public_ip" ]]; then
      # remove all double quotes
      public_ip=${public_ip//\"/}
      local public_ip_rule="-A INPUT -p tcp -s $public_ip -j ACCEPT"$'\n'
      local public_ip_rules="$public_ip_rules$public_ip_rule"
    fi
  done <<< "$public_ips"

  # private ip rules
  local private_ip_rules=""
  while read -r private_ip; do
    if [[ ! -z "$private_ip" ]]; then
      # remove all double quotes
      private_ip=${private_ip//\"/}
      local private_ip_rule="-A INPUT -p tcp -s $private_ip -j ACCEPT"$'\n'
      local private_ip_rules="$private_ip_rules$private_ip_rule"
    fi
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

  echo "$iptables_default_rules_start"'\n' >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
  if [[ ! -z "$public_ip_rules" ]]; then
    echo "# public ip lines" >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
    echo "$public_ip_rules" >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
  fi
  if [[ ! -z "$private_ip_rules" ]]; then
    echo "# private ip lines" >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
    echo "$private_ip_rules" >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
  fi
  if [[ ! -z "$extra_rules" ]]; then
    echo "# extra lines" >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
    echo "$extra_rules" >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
  fi
  echo "$iptables_default_rules_end" >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
}

watch_iptables_rules_file () {
  local end_loop=false
  local current_file="$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
  current_rules="$(/usr/bin/stat -c%s $current_file)"
  while [[ "$end_loop" != true ]]; do
    FILE_NAME="iptable_rules_watch"
    write_iptables_rules_file
    local new_file="$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
    new_rules="$(/usr/bin/stat -c%s $new_file)"
    new_rules_content="$(cat $new_file)"
    if [[ "$current_rules" != "$new_rules" && ("$new_rules_content" == *"private ip lines"* || "$new_rules_content" == *"public ip lines"*) ]]; then
      end_loop=true
    fi
    sleep "$REFRESH_TIME"
  done
}

if [[ "$MODE" == "init" ]]; then
  echo "writing iptables rules file at $(get_file_path_including_file_name $FILE_PATH $FILE_NAME)..."
  write_iptables_rules_file
else
  echo "watching changes for iptables rules file at $(get_file_path_including_file_name $FILE_PATH $FILE_NAME)..."
  watch_iptables_rules_file
fi