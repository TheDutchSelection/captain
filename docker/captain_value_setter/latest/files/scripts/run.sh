#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

for key_value in $ETCD_SHORT_KEYS_VALUES; do
  key="$(echo $key_value | awk -F'##' '{print $1}')"
  value="$(echo $key_value | awk -F'##' '{print $2}')"
  echo "set $ETCD_BASE_PATH$key to $value"
  set_etcd_value "$ETCD_BASE_PATH$key" "$value"
done