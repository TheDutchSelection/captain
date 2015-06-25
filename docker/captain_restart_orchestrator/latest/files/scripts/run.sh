#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

# $1: redis field
# $2: redis value
get_need_restart_keys_for_need_restart_value () {
  set -e
  local redis_need_restart_field="$1"
  local redis_need_restart_value="$2"
  local keys=""

  local redis_all_keys=$(get_redis_keys "$redis_namespace""*")

  for redis_key in $redis_all_keys
  do
    local redis_current_need_restart_value=$(get_redis_hash_value "$redis_key" "$redis_need_restart_field")
    if [[ "$redis_current_need_restart_value" == "$redis_need_restart_value" ]]; then
      if [[ -z "$keys" ]]; then
        local keys="$redis_key"
      else
        local keys="$keys"$'\n'"$redis_key"
      fi
    fi
  done

  echo "$keys"
}

# $1: app
get_max_restarts_for_app () {
  local app="$1"
  local max_restarts=1

  for app_exception_amount in $APP_EXCEPTIONS_AMOUNTS
  do
    local exception_app=$(echo "$app_exception_amount" | awk -F'\#\#\!\!' '{print $1}')
    local max_restart_value=$(echo "$app_exception_amount" | awk -F'\#\#\!\!' '{print $2}')
    if [[ "$exception_app" == *"$app"* ]]; then
      max_restarts="$max_restart_value"
      break
    fi
  done

  echo "$max_restarts"
}

# $1: need restart keys
# $2: update field
# $3: update value
# $4: restart field
# $5: restart value
# description: takes keys and sets the corresponding restart fields to the restart value, after checking
#              if the image is not updating or too many other containers are currently restarting
set_restart_fields () {
  local need_restart_keys="$1"
  local update_field="$2"
  local update_value="$3"
  local restart_field="$4"
  local restart_value="$5"

  local result=()

  while read -r need_restart_key; do
    if [[ ! -z "$need_restart_key" ]]; then
      local app=$(get_app_from_redis_key "$need_restart_key")
      local current_restarts=$(count_redis_hash_keys_with_field_with_value_for_app "$app" "$restart_field" "$restart_value")
      local max_restarts=$(get_max_restarts_for_app "$app")
      local current_update_value=$(get_redis_hash_value "$need_restart_key" "$update_field")
      local current_restart_value=$(get_redis_hash_value "$need_restart_key" "$restart_field")

      if [[ "$current_restart_value" = "$restart_value" ]]; then
        local result=("${result[@]}""$need_restart_key - currently restarting"'\n')
      elif [[ "$current_update_value" = "$update_value" ]]; then
        local result=("${result[@]}""$need_restart_key - currently updating"'\n')
      elif [[ "$max_restarts" > "$current_restarts" ]]; then
        local redis_result=$(set_redis_hash_value "$need_restart_key" "$restart_field" "$restart_value")
        local result=("${result[@]}""set field $restart_field from $need_restart_key to $restart_value with response from redis: $redis_result"'\n')
      else
        local result=("${result[@]}""$need_restart_key - max restarts ($max_restarts) reached (currently restarting: $current_restarts)"'\n')
      fi
    fi
  done <<< "$need_restart_keys"

  echo ${result[@]}
}

run_script () {
  echo "get $redis_need_restart_field where value is $redis_true_value every $REFRESH_TIME seconds..."
  while true; do
    local need_restart_keys=$(get_need_restart_keys_for_need_restart_value "$redis_need_restart_field" "$redis_true_value")

    local result=$(set_restart_fields "$need_restart_keys" "$redis_update_field" "$redis_true_value" "$redis_restart_field" "$redis_true_value")

    if [[ ! -z "$result" ]]; then
      echo -e "$result"
    fi

    sleep "$REFRESH_TIME"
  done
}

run_script &

wait
