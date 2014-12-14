#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/etcd_helper"

get_file_path_including_file_name () {
  echo "$FILE_PATH$FILE_NAME"
}

write_container_environment_file () {
  set -e
  mkdir -p $FILE_PATH
  cat /dev/null > "$(get_file_path_including_file_name)"

  local etcd_tree="$(get_tree $ETCD_BASE_PATH)"
  local key_values="$(echo $etcd_tree | $dir/jq '.node.nodes[] as $apps | $apps.nodes[] as $app_ids | $app_ids.nodes[] as $keys | $keys | .key + "##" + .value')"

  while read -r key_value; do
    # remove ETCD_BASE_PATH
    local app_key_value=${key_value/"$ETCD_BASE_PATH"/}
    # remove all double quotes
    app_key_value=${short_key_value//\"/}
    # split in key and value
    local key="$(echo $app_key_value | awk -F'##' '{print $1}')"
    local value="$(echo $app_key_value | awk -F'##' '{print $2}')"
    # check if the key is in the wanted keys and it is either host or port (all keys we want)
    include_key=false
    for app_key in $APP_KEYS
    do
      if [[ $key == *"$app_key"* && ($key == *"/host_"* || $key == *"/port"*) && ($key != *"$IGNORED_APP_KEY"*) ]]; then
        include_key=true
        break
      fi
    done

    if [[ "$include_key" == true ]]; then
      key="$(echo $key | awk '{print toupper($0)}')"
      key=${key//\//_}
      key=${key//\-/_}
      if [[ ! -z "$key" && ! -z "$value" ]]; then
        echo "$key=$value" >> "$(get_file_path_including_file_name)"
      fi
    fi
  done <<< "$key_values"
}

watch_container_environment_file () {
  local end_loop=false
  local current_file="$(get_file_path_including_file_name)"
  current_env="$(/usr/bin/stat -c%s $current_file)"
  while [[ "$end_loop" != true ]]; do
    # Now comparing on file size, because lines can shuffle per file. Should fix it by reading lines and comparing
    FILE_NAME="environment_watch"
    write_container_environment_file
    local new_file="$(get_file_path_including_file_name)"
    new_env="$(/usr/bin/stat -c%s $new_file)"
    if [[ "$current_env" != "$new_env" && "$new_env" != "0" ]]; then
      echo "new environment file is different..."
      current_need_restart_value="$(get_value $NEED_RESTART_KEY)"
      if [[ current_need_restart_value == "1" ]]; then
        echo "$ETCD_BASE_PATH$ETCD_CURRENT_APP$NEED_RESTART_KEY is already 1, doing nothing..."
      else
        echo "setting $ETCD_BASE_PATH$ETCD_CURRENT_APP$NEED_RESTART_KEY to 1"
        echo "$(set_value $ETCD_BASE_PATH$ETCD_CURRENT_APP$NEED_RESTART_KEY "1")"
        end_loop=true
      fi
    fi
    sleep "$REFRESH_TIME"
  done
}

if [[ "$MODE" == "init" ]]; then
  echo "writing environment file at $(get_file_path_including_file_name)..."
  write_container_environment_file
else
  echo "watching changes for environment file at $(get_file_path_including_file_name)..."
  watch_container_environment_file
fi