#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

# transforms ETCD_VALUE_NAME to /etcd/path/to/key
# $1: env_key
etcd_key_from_env () {
  env_key="$1"
  local key=${env_key/ETCD_VALUE_/}
  local key="$(echo $key | awk '{print tolower($0)}')"
  local key="$ETCD_BASE_PATH$key"

  echo "$key"
}

while true; do
  envs="$(env)"

  while read -r env; do
    # set every ETCD_VALUE_[NAME]
    if [[ $env == "ETCD_VALUE_"* ]]; then
      env_key="$(echo $env | awk -F'=' '{print $1}')"
      value="$(echo $env | awk -F'=' '{print $2}')"

      key="$(etcd_key_from_env $env_key)"

      if [[ (! -z "$key") && (! -z "$value") ]]; then
        echo "publish $key = $value to $ETCD_ENDPOINT with a ttl of $ETCD_TTL"
        echo "$(set_value $key $value $ETCD_TTL)"
      fi
    fi
  done <<< "$envs"

  sleep "$REFRESH_TIME"
done