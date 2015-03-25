#!/bin/bash
set -e

trap "exit" SIGINT SIGTERM

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

get_all_app_public_ips () {
  local etcd_tree=$(get_etcd_tree "$ETCD_BASE_PATH")
  local public_ips=$(echo "$etcd_tree" | jq '.nodes[] as $av_zones | $av_zones.nodes[] | select(.key | contains("/containers")) | .nodes[] as $apps | $apps.nodes[] as $app_ids | $app_ids.nodes[] | select(.key | contains("/host_public_ip")) | .key + "=" + .value')

  echo "$public_ips"
}

get_all_host_public_ips () {
  local etcd_tree=$(get_etcd_tree "$ETCD_BASE_PATH")
  local public_ips=$(echo "$etcd_tree" | jq '.nodes[] as $av_zones | $av_zones.nodes[] | select(.key | contains("/hosts")) | .nodes[] as $hosts | $hosts.nodes[] | select(.key | contains("/public_ip")) | .key + "=" + .value')

  echo "$public_ips"
}

get_app_private_ips () {
  local private_ips=""

  if [[ ! -z "$ETCD_CURRENT_AVZONE_PATH" ]]; then
    local etcd_tree_path="$ETCD_CURRENT_AVZONE_PATH"
    local etcd_tree=$(get_etcd_tree "$etcd_tree_path")
    local private_ips=$(echo "$etcd_tree" | jq '.nodes[] as $apps | $apps.nodes[] as $app_ids | $app_ids.nodes[] | select(.key | contains("/host_private_ip")) | .key + "=" + .value')
  fi

  echo "$private_ips"
}

get_app_ports () {
  local ports=""

  local etcd_tree=$(get_etcd_tree "$ETCD_BASE_PATH")
  local ports=$(echo "$etcd_tree" | jq '.nodes[] as $av_zones | $av_zones.nodes[] | select(.key | contains("/containers")) | .nodes[] as $apps | $apps.nodes[] as $app_ids | $app_ids.nodes[] | select(.key | contains("/host_port")) | .key + "=" + .value')
  echo "$ports"
}

# $1: etcd key values
create_app_envs () {
  local etcd_key_values="$1"
  local envs=""

  while read -r etcd_key_value; do
    for app_key in $APP_KEYS
    do
      if [[ "$etcd_key_value" == *"/$app_key"* && ( -z "$IGNORED_APP_KEY" || "$etcd_key_value" != *"$IGNORED_APP_KEY"*) ]]; then
        env=$(create_env_from_etcd_key_value "$etcd_key_value" "containers/")
        if [[ -z "$envs" ]]; then
          envs="$env"
        else
          envs="$envs"$'\n'"$env"
        fi
      fi
    done
  done <<< "$etcd_key_values"

  echo "$envs"
}

# $1: etcd key values
create_host_envs () {
  local etcd_key_values="$1"
  local envs=""

  while read -r etcd_key_value; do
    env=$(create_env_from_etcd_key_value "$etcd_key_value" "hosts/")
    if [[ -z "$envs" ]]; then
      envs="$env"
    else
      envs="$envs"$'\n'"$env"
    fi
  done <<< "$etcd_key_values"

  echo "$envs"
}

# $1: file path
# $1: file name
write_container_environment_file () {
  set -e
  local file_path="$1"
  local file_name="$2"
  
  create_empty_file "$file_path" "$file_name"

  if [[ ! -z "$APP_KEYS" ]]; then
    local app_public_ip_key_values=$(get_all_app_public_ips)
    local app_private_ip_key_values=$(get_app_private_ips)
    local app_port_key_values=$(get_app_ports)
    local app_public_ip_envs=$(create_app_envs "$app_public_ip_key_values")
    local app_private_ip_envs=$(create_app_envs "$app_private_ip_key_values")
    local app_port_envs=$(create_app_envs "$app_port_key_values")
    if [[ "$ALL_HOST_PUBLIC_IPS" == "1" ]]; then
      local host_public_ip_key_values=$(get_all_host_public_ips)
      local host_public_ip_envs=$(create_app_envs "$host_public_ip_key_values")
    fi

    # put all together
    local complete_file_path=$(get_file_path_including_file_name "$file_path" "$file_name")
    if [[ ! -z "$app_public_ip_envs" ]]; then
      echo "$app_public_ip_envs" >> "$complete_file_path"
    fi
    if [[ ! -z "$host_public_ip_envs" ]]; then
      echo "$host_public_ip_envs" >> "$complete_file_path"
    fi
    if [[ ! -z "$app_private_ip_envs" ]]; then
      echo "$app_private_ip_envs" >> "$complete_file_path"
    fi
    if [[ ! -z "$app_port_envs" ]]; then
      echo "$app_port_envs" >> "$complete_file_path"
    fi
  fi
}

# $1: file path
# $1: file name
watch_container_environment_file () {
  set -e
  local file_path="$1"
  local file_name="$2"

  local end_loop=false
  local current_file=$(get_file_path_including_file_name "$file_path" "$file_name")
  local current_envs=$(cat "$current_file" | sort)

  while [[ "$end_loop" != true ]]; do
    local file_name_watch="$file_name""_watch"
    write_container_environment_file "$file_path" "$file_name_watch"
    local new_file=$(get_file_path_including_file_name "$file_path" "$file_name_watch")
    local new_envs=$(cat "$new_file" | sort)
    if [[ "$current_envs" != "$new_envs" && ! -z "$new_envs" ]]; then
      echo "new environment file is different..."
      current_need_restart_value=$(get_etcd_value "$NEED_RESTART_KEY")
      if [[ current_need_restart_value != "$NEED_RESTART_VALUE" ]]; then
        set_etcd_value "$NEED_RESTART_KEY" "$NEED_RESTART_VALUE"
        result="current envs: $current_envs, new envs: $new_envs"
        end_loop=true
      fi
    fi
    sleep "$REFRESH_TIME"
  done

  echo "$result"
}

if [[ "$MODE" == "init" ]]; then
  echo "writing environment file at $(get_file_path_including_file_name $FILE_PATH $FILE_NAME)..."
  write_container_environment_file "$FILE_PATH" "$FILE_NAME"
else
  echo "watching changes for environment file at $(get_file_path_including_file_name $FILE_PATH $FILE_NAME)..."
  watch_environment_result=$(watch_container_environment_file "$FILE_PATH" "$FILE_NAME")
  echo "$watch_environment_result"
fi