#!/bin/bash
set -e

trap "exit" SIGINT SIGTERM

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

read -r -d '' iptables_nat_rules_start << EOM || true
*nat

:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:DOCKER - [0:0]

# Docker NAT rules
-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
-A OUTPUT -m addrtype --dst-type LOCAL ! -d 127.0.0.0/8 -j DOCKER
-A POSTROUTING ! -o docker0 -s 172.17.0.0/16 -j MASQUERADE
EOM

read -r -d '' iptables_nat_rules_end << EOM || true
COMMIT
EOM

read -r -d '' iptables_filter_rules_start << EOM || true
*filter

:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# General
-A INPUT -i lo -j ACCEPT
-A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
-A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
-A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
-A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Accept any established connections
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Accept SSH
-A INPUT -p tcp --dport 22 -j ACCEPT

# Allow docker forwarding
-A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -o docker0 -j ACCEPT
-A FORWARD -i docker0 -j ACCEPT
EOM

read -r -d '' iptables_filter_rules_end << EOM || true
# Log and drop everything else
-A INPUT -j LOG
-A INPUT -j DROP
-A FORWARD -j LOG
-A FORWARD -j DROP

COMMIT
EOM

# $1: container_ips_with_keys
docker_nat_rules () {
  # "/tds/doa3/containers/haproxy/doa3wrkprd001/container_ip=172.17.0.6"
  local container_ips_with_keys="$1"
  local nat_rules=""
  while read -r container_ip_with_key; do
    if [[ ! -z "$container_ip_with_key" ]]; then
      # remove all double quotes
      container_ip_with_key=${container_ip_with_key//\"/}
      local container_ip_key=$(echo "$container_ip_with_key" | awk -F'=' '{print $1}')
      local container_ip=$(echo "$container_ip_with_key" | awk -F'=' '{print $2}')
      local container_port_key=${container_ip_with_key/container_ip/container_port}
      local container_port_extra_key=${container_ip_with_key/container_ip/container_port_extra}
      local container_port_peer_key=${container_ip_with_key/container_ip/container_port_peer}
      local container_port_data_sync_key=${container_ip_with_key/container_ip/container_port_data_sync}
      local container_port=$(get_etcd_value "$container_port_key")
      local container_port_extra=$(get_etcd_value "$container_port_extra_key")
      local container_port_peer=$(get_etcd_value "$container_port_peer_key")
      local container_port_data_sync=$(get_etcd_value "$container_port_data_sync_key")
      
      if [[ ! -z "$container_port" ]]; then
        local nat_rule=$(docker_nat_rule "$container_ip" "$container_port")
        local nat_rules="$nat_rules$nat_rule"
      fi

      if [[ ! -z "$container_port_extra" ]]; then
        local nat_rule=$(docker_nat_rule "$container_ip" "$container_port_extra")
        local nat_rules="$nat_rules$nat_rule"
      fi
      
      if [[ ! -z "$container_port_peer" ]]; then
        local nat_rule=$(docker_nat_rule "$container_ip" "$container_port_peer")
        local nat_rules="$nat_rules$nat_rule"
      fi
      
      if [[ ! -z "$container_port_data_sync" ]]; then
        local nat_rule=$(docker_nat_rule "$container_ip" "$container_port_data_sync")
        local nat_rules="$nat_rules$nat_rule"
      fi
      
    fi
  done <<< "$container_ips_with_keys"

  # echo "$nat_rules"
  echo "$container_ips_with_keys"
}

# $1: container_ip
# $2: container_port
docker_nat_rule () {
  local container_ip="$1"
  local container_port="$2"
  local nat_rule="-A DOCKER ! -i docker0 -p tcp --dport $container_port -j DNAT --to-destination $container_ip:$container_port"$'\n'"-A DOCKER ! -i docker0 -p udp --dport $container_port -j DNAT --to-destination $container_ip:$container_port"$'\n'

  echo "$nat_rule"
}

extra_rules () {
  envs=$(env)
  local extra_rules=""

  # every extra rule env starts with IPTABLES_RULE
  while read -r env; do
    if [[ "$env" == "IPTABLES_RULE_"* ]]; then
      local extra_rule=$(echo "$env" | awk -F'=' '{print $2}')
      local extra_rule="$extra_rule"$'\n'
      local extra_rules="$extra_rules$extra_rule"
    fi
  done <<< "$envs"

  echo "$extra_rules"
}

# $1: ips
trusted_ip_rules () {
  local ips="$1"
  local ip_rules=""
  while read -r ip; do
    if [[ ! -z "$ip" ]]; then
      # remove all double quotes
      ip=${ip//\"/}
      local ip_rule="-A INPUT -p tcp -s $ip -j ACCEPT"$'\n'"-A INPUT -p udp -s $ip -j ACCEPT"$'\n'"-A FORWARD -p tcp -s $ip -j ACCEPT"$'\n'"-A FORWARD -p udp -s $ip -j ACCEPT"$'\n'
      local ip_rules="$ip_rules$ip_rule"
    fi
  done <<< "$ips"

  echo "$ip_rules"
}

get_all_public_ips () {
  local etcd_tree=$(get_etcd_tree "$ETCD_BASE_PATH")
  local public_ips=$(echo "$etcd_tree" | "$dir"/jq '.nodes[] as $av_zones | $av_zones.nodes[] | select(.key | contains("/hosts")) | .nodes[] as $hosts | $hosts.nodes[] as $keys | $keys | select(.key | contains("/public_ip")) | .value')

  echo "$public_ips"
}

get_private_ips () {
  local private_ips=""

  if [[ ! -z "$ETCD_CURRENT_AVZONE_PATH" ]]; then
    local etcd_tree_path="$ETCD_CURRENT_AVZONE_PATH""hosts/"
    local etcd_tree=$(get_etcd_tree "$etcd_tree_path")
    local private_ips=$(echo "$etcd_tree" | "$dir"/jq '.nodes[] as $hosts | $hosts.nodes[] as $keys | $keys | select(.key | contains("/private_ip")) | .value')
  fi

  echo "$private_ips"
}

get_container_ips_with_keys () {
  local container_ips_with_keys=""

  if [[ ! -z "$ETCD_CURRENT_AVZONE_PATH" && ! -z "$CURRENT_HOST" ]]; then
    local etcd_tree_path="$ETCD_CURRENT_AVZONE_PATH""containers/"
    local etcd_tree=$(get_etcd_tree "$etcd_tree_path")
    local container_ips_with_keys=$(echo "$etcd_tree" | "$dir"/jq '.nodes[] as $containers | $containers.nodes[] as $hosts | $hosts | select(.key | contains("/'"$CURRENT_HOST"'")) as $host | $host.nodes[] as $keys | $keys | select(.key | contains("/container_ip")) | .key + "=" + .value')
  fi

  echo "$container_ips_with_keys"
}

# $1: file path
# $1: file name
write_iptables_rules_file () {
  set -e
  local file_path="$1"
  local file_name="$2"

  create_empty_file "$file_path" "$file_name"

  local public_ips=$(get_all_public_ips)
  local private_ips=$(get_private_ips)
  local container_ips_with_keys=$(get_container_ips_with_keys)
  local public_ip_rules=$(trusted_ip_rules "$public_ips")
  local private_ip_rules=$(trusted_ip_rules "$private_ips")
  local container_nat_rules=$(docker_nat_rules "$container_ips_with_keys")
  local extra_rules=$(extra_rules)

  # put all together
  local complete_file_path=$(get_file_path_including_file_name "$file_path" "$file_name")
  echo "$iptables_filter_rules_start"$'\n' >> "$complete_file_path"
  if [[ ! -z "$public_ip_rules" ]]; then
    echo "# public ip lines" >> "$complete_file_path"
    echo "$public_ip_rules" >> "$complete_file_path"
  fi
  if [[ ! -z "$private_ip_rules" ]]; then
    echo "# private ip lines" >> "$complete_file_path"
    echo "$private_ip_rules" >> "$complete_file_path"
  fi
  if [[ ! -z "$extra_rules" ]]; then
    echo "# extra lines" >> "$complete_file_path"
    echo "$extra_rules" >> "$complete_file_path"
  fi
  echo "$iptables_filter_rules_end" >> "$complete_file_path"

  echo "$iptables_nat_rules_start"$'\n' >> "$complete_file_path"
  if [[ ! -z "$container_nat_rules" ]]; then
    echo "# container ip and port nat lines" >> "$complete_file_path"
    echo "$container_nat_rules" >> "$complete_file_path"
  fi
  echo "$iptables_nat_rules_end" >> "$complete_file_path"
}

# $1: file path
# $1: file name
watch_iptables_rules_file () {
  set -e
  local file_path="$1"
  local file_name="$2"

  local end_loop=false
  local current_file=$(get_file_path_including_file_name "$file_path" "$file_name")
  local current_rules=$(cat "$current_file" | sort)

  while [[ "$end_loop" != true ]]; do
    file_name_watch="$file_name""_watch"
    write_iptables_rules_file "$file_path" "$file_name_watch"
    local new_file=$(get_file_path_including_file_name "$file_path" "$file_name_watch")
    local new_rules=$(cat "$new_file" | sort)
    if [[ "$current_rules" != "$new_rules" && ("$new_rules" == *"private ip lines"* || "$new_rules" == *"public ip lines"*) ]]; then
      local end_loop=true
    fi
    sleep "$REFRESH_TIME"
  done
}

if [[ "$MODE" == "init" ]]; then
  echo "writing iptables rules file at $(get_file_path_including_file_name $FILE_PATH $FILE_NAME)..."
  write_iptables_rules_file "$FILE_PATH" "$FILE_NAME"
else
  echo "watching changes for iptables rules file at $(get_file_path_including_file_name $FILE_PATH $FILE_NAME)..."
  watch_iptables_rules_file "$FILE_PATH" "$FILE_NAME"
fi