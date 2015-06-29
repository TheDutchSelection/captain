#!/bin/bash

# variables, can be overwritten by defining them again
data_image_name="thedutchselection/data"
data_image_tag="latest"
elasticsearch_image_name="thedutchselection/elasticsearch"
elasticsearch_image_tag="1.5.0"
postgresql_image_name="thedutchselection/postgresql"
postgresql_image_tag="9.3.5"
redis_image_name="thedutchselection/redis"
redis_image_tag="2.8.18"

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
start_elasticsearch_container () {
  set -e
  local container_name="$1"
  local data_container_name="$2"

  start_data_container "$data_container_name" "/home/elastic/data" "9200" "9200"

  docker pull "$elasticsearch_image_name":"$elasticsearch_image_tag" || true

  docker run \
  --name "$container_name" \
  -d \
  -e "CLUSTER_NAME=test" \
  -e "NODE_NAME=test_node" \
  -e "NODE_MASTER=true" \
  -e "NODE_DATA=true" \
  -e "MAX_LOCAL_STORAGE_NODES=1" \
  -e "NUMBER_OF_SHARDS=5" \
  -e "NUMBER_OF_REPLICAS=0" \
  -e "PATH_DATA=/home/elastic/data/data" \
  -e "PATH_WORK=/home/elastic/data/work" \
  -e "PATH_LOGS=/home/elastic/data/logs" \
  -e "PUBLISH_HOST=127.0.0.1" \
  -e "TRANSPORT_PORT=9300" \
  -e "HTTP_PORT=9200" \
  -e "DATA_DIRECTORY=/home/elasticsearch/data" \
  -e "SUPERUSER_USERNAME=$elasticsearch_user_name" \
  -e "SUPERUSER_PASSWORD=$elasticsearch_password" \
  --volumes-from "$data_container_name" \
  -p :9200 \
  -p :9200/udp \
  "$elasticsearch_image_name":"$elasticsearch_image_tag" &

  sleep 1

  elasticsearch_host=$(docker inspect --format '{{ .NetworkSettings.Gateway }}' "$container_name")
  elasticsearch_port=$(docker inspect --format '{{(index (index .NetworkSettings.Ports "9200/tcp") 0).HostPort }}' "$container_name")
}

# $1: container name
# $2: data container name
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

# $1: container name
# $2: data container name
start_redis_container () {
  set -e
  local container_name="$1"
  local data_container_name="$2"

  start_data_container "$data_container_name" "/home/redis/data" "6379" "6379"

  docker pull "$redis_image_name":"$redis_image_tag" || true

  docker run \
  --name "$container_name" \
  -d \
  -e "DATA_DIRECTORY=/home/redis/data" \
  --volumes-from "$data_container_name" \
  -p :6379 \
  -p :6379/udp \
  "$redis_image_name":"$redis_image_tag" &

  sleep 1

  redis_host=$(docker inspect --format '{{ .NetworkSettings.Gateway }}' "$container_name")
  redis_port=$(docker inspect --format '{{(index (index .NetworkSettings.Ports "6379/tcp") 0).HostPort }}' "$container_name")
}
