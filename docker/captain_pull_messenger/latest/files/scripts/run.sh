#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

pull_docker_image_command () {
  echo "/usr/bin/docker pull $IMAGE_COMPLETE"
}

value="$(get_value $ETCD_KEY)"
if [[ "$value" != "$ETCD_NO_PULL_VALUE" ]]; then
  echo "$(pull_docker_image_command)"
else
  echo ""
fi