#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

run_script () {
  local key=$(create_redis_containers_hash_key "$REDIS_APP_AVZONE" "$REDIS_APP" "$REDIS_APP_HOST")
  local field=$(echo "$REDIS_FIELD_VALUE" | awk -F'\#\#\!\!' '{print $1}')
  local value=$(echo "$REDIS_FIELD_VALUE" | awk -F'\#\#\!\!' '{print $2}')
  local end_loop=false

  echo "watching field $field from $key for $value..."
  while [[ "$end_loop" != true ]]; do
    sleep "$REFRESH_TIME"
    local redis_value=$(get_redis_hash_value "$key" "$field")
    if [[ "$redis_value" == "$value" ]]; then
      echo "field $field from $key is $value, exiting..."
      local end_loop=true
    fi
  done
}

run_script &

wait
