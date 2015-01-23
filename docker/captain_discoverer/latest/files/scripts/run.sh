#!/bin/bash
set -e

trap "exit" SIGINT SIGTERM

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

get_all_public_ips () {
  local etcd_tree=$(get_etcd_tree "$ETCD_BASE_PATH")
  local public_ips=$(echo "$etcd_tree" | "$dir"/jq '.nodes[] as $av_zones | $av_zones.nodes[] | select(.key | contains("/containers")) | .nodes[] as $apps | $apps.nodes[] as $app_ids | $app_ids.nodes[] | select(.key | contains("/host_public_ip")) | .key + "=" + .value')

  echo "$public_ips"
}

get_private_ips () {
  local private_ips=""

  if [[ ! -z "$ETCD_CURRENT_AVZONE_PATH" ]]; then
    local etcd_tree_path="$ETCD_CURRENT_AVZONE_PATH"
    local etcd_tree=$(get_etcd_tree "$etcd_tree_path")
    local private_ips=$(echo "$etcd_tree" | "$dir"/jq '.nodes[] as $apps | $apps.nodes[] as $app_ids | $app_ids.nodes[] | select(.key | contains("/host_private_ip")) | .key + "=" + .value')
  fi

  echo "$private_ips"
}

get_ports () {
  local ports=""

  if [[ ! -z "$ETCD_CURRENT_AVZONE_PATH" ]]; then
    local etcd_tree_path="$ETCD_CURRENT_AVZONE_PATH"
    local etcd_tree=$(get_etcd_tree "$etcd_tree_path")
    local ports=$(echo "$etcd_tree" | "$dir"/jq '.nodes[] as $apps | $apps.nodes[] as $app_ids | $app_ids.nodes[] | select(.key | contains("/host_port")) | .key + "=" + .value')
  fi

  echo "$ports"
}

# $1: etcd key values
create_envs () {
  local etcd_key_values="$1"
  local envs=""

  while read -r etcd_key_value; do
    include_key=false
    for app_key in $APP_KEYS
    do
      if [[ "$etcd_key_value" == *"/$app_key"* && ( -z "$IGNORED_APP_KEY" || "$etcd_key_value" != *"$IGNORED_APP_KEY"*) ]]; then
        env=$(create_env_from_etcd_key_value "$etcd_key_value" "$ETCD_CURRENT_AVZONE_PATH")
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

# $1: file path
# $1: file name
write_container_environment_file () {
  set -e
  local file_path="$1"
  local file_name="$2"
  
  create_empty_file "$file_path" "$file_name"

  if [[ ! -z "$APP_KEYS" ]]; then
    local public_ip_key_values=$(get_all_public_ips)
    local private_ip_key_values=$(get_private_ips)
    local port_key_values=$(get_ports)
    local public_ip_envs=$(create_envs "$public_ip_key_values")
    local private_ip_envs=$(create_envs "$private_ip_key_values")
    local port_envs=$(create_envs "$port_key_values")

    # put all together
    local complete_file_path=$(get_file_path_including_file_name "$file_path" "$file_name")
    if [[ ! -z "$public_ip_envs" ]]; then
      echo "$public_ip_envs" >> "$complete_file_path"
    fi
    if [[ ! -z "$private_ip_envs" ]]; then
      echo "$private_ip_envs" >> "$complete_file_path"
    fi
    if [[ ! -z "$port_envs" ]]; then
      echo "$port_envs" >> "$complete_file_path"
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