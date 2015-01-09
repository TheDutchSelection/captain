#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

write_container_environment_file () {
  set -e
  create_empty_file "$FILE_PATH" "$FILE_NAME"

  # get all public ips
  local etcd_tree="$(get_tree $ETCD_BASE_PATH)"
  local public_ips="$(echo $etcd_tree | $dir/jq '.nodes[] as $av_zones | $av_zones.nodes[] | select(.key | contains("/containers")) | .nodes[] as $apps | $apps.nodes[] as $app_ids | $app_ids.nodes[] | select(.key | contains("/host_public_ip")) | .key + "=" + .value')"
  # get private ips and ports from this zone
  local etcd_tree="$(get_tree $ETCD_CURRENT_AVZONE_PATH)"
  local private_ips="$(echo $etcd_tree | $dir/jq '.nodes[] as $apps | $apps.nodes[] as $app_ids | $app_ids.nodes[] | select(.key | contains("/host_private_ip")) | .key + "=" + .value')"
  local ports="$(echo $etcd_tree | $dir/jq '.nodes[] as $apps | $apps.nodes[] as $app_ids | $app_ids.nodes[] | select(.key | contains("/port")) | .key + "=" + .value')"
  
  # public ips
  local public_ip_envs=""
  while read -r public_ip; do
    include_key=false
    for app_key in $APP_KEYS
    do
      if [[ $public_ip == *"/$app_key"* && ( -z "$IGNORED_APP_KEY" || $public_ip != *"$IGNORED_APP_KEY"*) ]]; then
        include_key=true
        break
      fi
    done
    
    if [[ "$include_key" == true ]]; then
      public_ip_env="$(create_env_from_etcd_key_value $public_ip $ETCD_CURRENT_AVZONE_PATH)"
      if [[ ! -z "$public_ip_envs" ]]; then
        public_ip_envs="$public_ip_envs"$'\n'"$public_ip_env"
      else
        public_ip_envs="$public_ip_env"
      fi
    fi
  done <<< "$public_ips"
  
  # private ips
  local private_ip_envs=""
  while read -r private_ip; do
    include_key=false
    for app_key in $APP_KEYS
    do
      if [[ $private_ip == *"/$app_key"* && ( -z "$IGNORED_APP_KEY" || $private_ip != *"$IGNORED_APP_KEY"*) ]]; then
        include_key=true
        break
      fi
    done
    
    if [[ "$include_key" == true ]]; then
      private_ip_env="$(create_env_from_etcd_key_value $private_ip $ETCD_CURRENT_AVZONE_PATH)"
      if [[ ! -z "$private_ip_envs" ]]; then
        private_ip_envs="$private_ip_envs"$'\n'"$private_ip_env"
      else
        private_ip_envs="$private_ip_env"
      fi
    fi
  done <<< "$private_ips"
  
  # ports
  local port_envs=""
  while read -r port; do
    include_key=false
    for app_key in $APP_KEYS
    do
      if [[ $port == *"/$app_key"* && ( -z "$IGNORED_APP_KEY" || $port != *"$IGNORED_APP_KEY"*) ]]; then
        include_key=true
        break
      fi
    done
    
    if [[ "$include_key" == true ]]; then
      port_env="$(create_env_from_etcd_key_value $port $ETCD_CURRENT_AVZONE_PATH)"
      if [[ ! -z "$port_envs" ]]; then
        port_envs="$port_envs"$'\n'"$port_env"
      else
        port_envs="$port_env"
      fi
    fi
  done <<< "$ports"
  
  # put all together
  if [[ ! -z "$public_ip_envs" ]]; then
    echo "$public_ip_envs" >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
  fi
  if [[ ! -z "$private_ip_envs" ]]; then
    echo "$private_ip_envs" >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
  fi
  if [[ ! -z "$port_envs" ]]; then
    echo "$port_envs" >> "$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
  fi
}

watch_container_environment_file () {
  local end_loop=false
  local current_file="$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
  current_env="$(/usr/bin/stat -c%s $current_file)"
  while [[ "$end_loop" != true ]]; do
    # Now comparing on file size, because lines can shuffle per file. Should fix it by reading lines and comparing
    FILE_NAME="environment_watch"
    write_container_environment_file
    local new_file="$(get_file_path_including_file_name $FILE_PATH $FILE_NAME)"
    new_env="$(/usr/bin/stat -c%s $new_file)"
    if [[ "$current_env" != "$new_env" && "$new_env" != "0" ]]; then
      echo "new environment file is different..."
      current_need_restart_value="$(get_value $NEED_RESTART_KEY)"
      if [[ current_need_restart_value == "1" ]]; then
        echo "$NEED_RESTART_KEY is already 1, doing nothing..."
      else
        echo "setting $NEED_RESTART_KEY to 1"
        echo "$(set_value $NEED_RESTART_KEY 1)"
        end_loop=true
      fi
    fi
    sleep "$REFRESH_TIME"
  done
}

if [[ "$MODE" == "init" ]]; then
  echo "writing environment file at $(get_file_path_including_file_name $FILE_PATH $FILE_NAME)..."
  write_container_environment_file
else
  echo "watching changes for environment file at $(get_file_path_including_file_name $FILE_PATH $FILE_NAME)..."
  watch_container_environment_file
fi