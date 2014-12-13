#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/etcd_helper"

get_keys_values_from_etcd_values () {
  envs="$(env)"

  local key_values=""
  while read -r env; do
    if [[ $env == *"ETCD_VALUE_"* ]]; then
      local key_value=${env/ETCD_VALUE_/}
      local key="$(echo $key_value | awk -F'=' '{print $1}')"
      local value="$(echo $key_value | awk -F'=' '{print $2}')"
      local key="$(echo $key | awk '{print tolower($0)}')"

      local key_values="$key_values$key##$value "
    fi
  done <<< "$envs"

  echo "$key_values"
}

keys_values="$(get_keys_values_from_etcd_values)"
while true; do
  for key_value in $keys_values
  do
    etcd_key="$(echo $key_value | awk -F'##' '{print $1}')"
    etcd_value="$(echo $key_value | awk -F'##' '{print $2}')"

    echo "publish $ETCD_BASE_PATH$etcd_key = $etcd_value to $ETCD_ENDPOINT with a ttl of $ETCD_TTL"
    echo "$(set_value $ETCD_BASE_PATH$etcd_key $etcd_value $ETCD_TTL)"
  done

  sleep "$REFRESH_TIME"
done