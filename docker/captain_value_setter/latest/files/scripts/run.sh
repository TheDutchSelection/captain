#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

run_script () {
  local result=()
  for field_value in $REDIS_FIELDS_VALUES; do
    local key=$(create_redis_containers_hash_key "$REDIS_APP_AVZONE" "$REDIS_APP" "$REDIS_APP_HOST")
    local field=$(echo "$field_value" | awk -F'\#\#\!\!' '{print $1}')
    local value=$(echo "$field_value" | awk -F'\#\#\!\!' '{print $2}')

    local redis_result=$(set_redis_hash_value "$key" "$field" "$value")
    local result=("${result[@]}""set field $field from $key to $value with response from redis: $redis_result"'\n')
  done

  echo ${result[@]}
}

echo -e $(run_script) &

wait