#!/bin/bash
set -e

trap "exit" SIGINT SIGTERM

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

# $1: etcd app path
get_max_restarts_for_app () {
  local etcd_app_path="$1"
  local max_restarts=1

  for app_exception in $APP_EXCEPTIONS
  do
    local partial_etcd_key=$(echo "$app_exception" | awk -F'##' '{print $1}')
    local max_restart_value=$(echo "$app_exception" | awk -F'##' '{print $2}')
    if [[ "/$partial_etcd_key" == *"$etcd_app_path"* ]]; then
      max_restarts="$max_restart_value"
      break
    fi
  done

  echo "$max_restarts"
}

# $1: need restart keys
# $2: partial need restart key
# $4: partial update key
# $5: update value
# $6: partial restart key
# $7: restart value
# description: takes need restart keys and sets the corresponding restart keys to the restart value, after checking
#              if the image is not updating or too many other containers are currently restarting
set_restart_values_from_need_restart_keys () {
  local need_restart_keys="$1"
  local partial_need_restart_key="$2"
  local partial_update_key="$3"
  local update_value="$4"
  local partial_restart_key="$5"
  local restart_value="$6"

  local result=""

  while read -r need_restart_key; do
    if [[ ! -z "$need_restart_key" ]]; then
      local relevant_etcd_app_path=$(get_etcd_app_path_from_app_key "$need_restart_key")
      local current_restarts=$(count_etcd_keys_with_value_for_app "$relevant_etcd_app_path" "$restart_key" "$restart_value")
      local max_restarts=$(get_max_restarts_for_app "$relevant_etcd_app_path")
      local current_update_value=$(get_etcd_value_from_other_key "$need_restart_key" "$partial_need_restart_key" "$partial_update_key")

      if [[ "$max_restarts" > "$current_restarts" ]]; then
        if [[ "$current_update_value" = "$update_value" ]]; then
          local result="$result"$'\n'"$need_restart_key - currently updating"
        else
          local result="$result"$'\n'"$need_restart_key - set $partial_restart_key to $restart_value"
          set_etcd_value_from_other_key "$need_restart_key" "$partial_need_restart_key" "$partial_restart_key" "$restart_value"
        fi
      else
        local result="$result"$'\n'"$need_restart_key - max restarts ($max_restarts) reached (currently restarting: $current_restarts)"
        local result="$result"$'\n'"partial_need_restart_key: $partial_need_restart_key"$'\n'"partial_update_key: $partial_update_key"$'\n'"update_value: $update_value"$'\n'"partial_restart_key: $partial_restart_key"$'\n'"restart_value: $restart_value"
      fi
    fi
  done <<< "$need_restart_keys"

  echo "$result"
}

partial_need_restart_key=$(echo "$ETCD_NEED_RESTART_KEY_VALUE" | awk -F'##' '{print $1}')
need_restart_value=$(echo "$ETCD_NEED_RESTART_KEY_VALUE" | awk -F'##' '{print $2}')
partial_update_key=$(echo "$ETCD_UPDATE_KEY_VALUE" | awk -F'##' '{print $1}')
update_value=$(echo "$ETCD_UPDATE_KEY_VALUE" | awk -F'##' '{print $2}')
partial_restart_key=$(echo "$ETCD_RESTART_KEY_VALUE" | awk -F'##' '{print $1}')
restart_value=$(echo "$ETCD_RESTART_KEY_VALUE" | awk -F'##' '{print $2}')

echo "get $partial_need_restart_key where value is $need_restart_value every $REFRESH_TIME seconds..."
while true; do
  need_restart_keys=$(get_etcd_keys_from_partial_key_with_value "$ETCD_BASE_PATH" "$partial_need_restart_key" "$need_restart_value")

  echo $(set_restart_values_from_need_restart_keys "$need_restart_keys" "$partial_need_restart_key" "$partial_update_key" "$update_value" "$partial_restart_key" "$restart_value")
  sleep "$REFRESH_TIME"
done