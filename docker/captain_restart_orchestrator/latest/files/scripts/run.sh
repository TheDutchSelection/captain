#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

# $1: etcd need restart key
set_restart_from_needs_restart_etcd_key () {
  local need_restart_key="$1"
  local restart_key="$(echo $need_restart_key | awk -F'/' '{print "/"$2"/"$3"/"$4"/"$5"/"$6"/"}')$restart_key"
  local current_restart_value=$(get_value "$restart_key")
  if [[ "$current_restart_value" != "$restart_value" ]]; then
    set_value "$restart_key" "$restart_value"
  fi
}

while true; do
  short_need_restart_key="$(echo $ETCD_NEED_RESTART_KEY_VALUE | awk -F'##' '{print $1}')"
  need_restart_value="$(echo $ETCD_NEED_RESTART_KEY_VALUE | awk -F'##' '{print $2}')"
  restart_key="$(echo $ETCD_RESTART_KEY_VALUE | awk -F'##' '{print $1}')"
  restart_value="$(echo $ETCD_RESTART_KEY_VALUE | awk -F'##' '{print $2}')"

  echo "get $short_need_restart_key where value is $need_restart_value"
  need_restart_keys="$(get_keys_from_short_key_with_value $ETCD_BASE_PATH $short_need_restart_key $need_restart_value)"

  echo "ETCD_BASE_PATH: $ETCD_BASE_PATH"
  echo "short_need_restart_key: $short_need_restart_key"
  echo "need_restart_value: $need_restart_value"
  echo "need_restart_keys: $need_restart_keys"
  # walk through all containers that need a restart
  while read -r need_restart_key; do
    echo "$need_restart_key is $need_restart_value, container needs restart"
    # get the relevant apps path
    relevant_etcd_app_path="$(get_app_path_from_app_key $need_restart_key)"

    echo "checking how many containers are restarting for $relevant_etcd_app_path..."
    # count the current amount of restarts processing for the app path
    current_restarts="$(count_keys_with_value_for_app $relevant_etcd_app_path $restart_key $restart_value)"
    echo "$current_restarts"

    # set the max restarts for this app
    max_restarts=1
    for app_exception in $APP_EXCEPTIONS
    do
      short_etcd_key="$(echo $app_exception | awk -F'##' '{print $1}')"
      max_restart_value="$(echo $app_exception | awk -F'##' '{print $2}')"
      if [[ "/$short_etcd_key" == *"$relevant_etcd_app_path"* ]]; then
        max_restarts="$max_restart_value"
        break
      fi
    done

    echo "max restarts for $relevant_etcd_app_path is $max_restarts"
    if [[ "$max_restarts" > "$current_restarts" ]]; then
      echo "setting restart value for container with $need_restart_key"
      set_restart_from_needs_restart_etcd_key "$need_restart_key"
    else
      echo "max restarts reached, not restarting"
    fi
  done <<< "$need_restart_keys"
  sleep "$REFRESH_TIME"
done