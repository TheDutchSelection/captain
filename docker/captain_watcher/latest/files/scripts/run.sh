#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

echo "watching $ETCD_KEY for value $ETCD_VALUE..."
end_loop=false
while [[ "$end_loop" != true ]]; do
  sleep "$REFRESH_TIME"
  value="$(get_value $ETCD_KEY)"
  if [[ "$value" == "$ETCD_VALUE" ]]; then
    echo "$ETCD_KEY is $ETCD_VALUE, exiting..."
    end_loop=true
  fi
done