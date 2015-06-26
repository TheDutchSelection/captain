#!/bin/bash

# variables, can be overwritten by defining them again
data_image_name="thedutchselection/data"
data_image_tag="latest"
postgresql_image_name="thedutchselection/postgresql"
postgresql_image_tag="9.3.5"

clean_up_images () {
  docker rmi $(/usr/bin/docker images -q -f 'dangling=true') || true
}

# $1: container names (separated by spaces)
clean_up_containers () {
  set -e
  local container_names="$1"

  for container_name in $container_names
  do
    docker stop "$container_name" || true
    docker kill "$container_name" || true
    docker rm "$container_name" || true
  done
}

# $1: data container name
# $2: data directory
# $3: data user id
# $4: data group id
start_data_container () {
  set -e
  local data_container_name="$1"
  local data_directory="$2"
  local data_user_id="$3"
  local data_group_id="$4"

  docker pull "$data_image_name":"$data_image_tag" || true

  docker run \
  --name "$data_container_name" \
  -e "DATA_DIRECTORY=$data_directory" \
  -e "USER_ID=$data_user_id" \
  -e "GROUP_ID=$data_group_id" \
  -v "$data_directory" \
  "$data_image_name":"$data_image_tag"
}

# $1: container name
# $2: data container name
# $3: data directory
# $4: superuser name
# $5: superuser password
start_postgresql_container () {
  set -e
  local container_name="$1"
  local data_container_name="$2"

  postgresql_user_name="test"
  postgresql_password="test123test"

  start_data_container "$data_container_name" "/home/postgresql/data" "5432" "5432"

  docker pull "$postgresql_image_name":"$postgresql_image_tag" || true

  docker run \
  --name "$container_name" \
  -d \
  -e "DATA_DIRECTORY=/home/postgresql/data" \
  -e "SUPERUSER_USERNAME=$postgresql_user_name" \
  -e "SUPERUSER_PASSWORD=$postgresql_password" \
  --volumes-from "$data_container_name" \
  -p :5432 \
  -p :5432/udp \
  "$postgresql_image_name":"$postgresql_image_tag" &

  sleep 1

  postgresql_host=$(docker inspect --format '{{ .NetworkSettings.Gateway }}' "$container_name")
  postgresql_port=$(docker inspect --format '{{(index (index .NetworkSettings.Ports "5432/tcp") 0).HostPort }}' "$container_name")
}
