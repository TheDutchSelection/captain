#!/bin/bash
set -e

trap "exit" SIGINT SIGTERM

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

while true; do
  envs="$(env)"

  while read -r env; do
    # set every ETCD_VALUE_[NAME]
    if [[ $env == "ETCD_VALUE_"* ]]; then
      env_key="$(echo $env | awk -F'=' '{print $1}')"
      value="$(echo $env | awk -F'=' '{print $2}')"

      key="$(create_etcd_key_from_env $env_key $ETCD_BASE_PATH)"

      if [[ (! -z "$key") && (! -z "$value") ]]; then
        echo "publish $key = $value to $ETCD_ENDPOINT with a ttl of $ETCD_TTL"
        echo "$(set_etcd_value $key $value $ETCD_TTL)"
      fi
    fi
  done <<< "$envs"

  sleep "$REFRESH_TIME"
done