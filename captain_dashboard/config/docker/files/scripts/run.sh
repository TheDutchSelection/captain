#!/bin/bash
set -e

# $1: host_variable
# $2: port_variable
# $3: avzone
# $4: search_variable_prefix
set_address_and_port () {
  set -e
  local host_variable_name="$1"
  local port_variable_name="$2"
  local avzone="$3"
  local search_variable_prefix="$4"

  eval host_variable=\$$host_variable_name
  eval port_variable=\$$port_variable_name

  if [[ -z "$host_variable" || -z "$port_variable" ]]; then
    local envs=$(env)
    local avzone_upper=$(echo "$avzone" | awk '{print toupper($0)}')
    while read -r env; do
      # do we have a private env or public env
      if [[ "$env" == "$search_variable_prefix""_$avzone_upper"* && "$env" == *"_HOST_PRIVATE_IP"* && ! -z "$avzone" ]]; then
        local host_var=$(echo "$env" | awk -F'=' '{print $1}')
        local host_address=$(echo "$env" | awk -F'=' '{print $2}')
        local port_var=${host_var/_PRIVATE_IP/_PORT}
        eval port=\$$port_var
      elif  [[ "$env" == "$search_variable_prefix""_$avzone_upper"* && "$env" == *"_HOST_PUBLIC_IP"* && ! -z "$avzone" ]]; then
        # set only if not set yet, will be overwritten later by private addresses if they exist
        if [[ -z "$host_address" ]]; then
          local host_var=$(echo "$env" | awk -F'=' '{print $1}')
          local host_address=$(echo "$env" | awk -F'=' '{print $2}')
          local port_var=${host_var/_PUBLIC_IP/_PORT}
          eval port=\$$port_var
        fi
      fi
    done <<< "$envs"

    eval $host_variable_name="$host_address"
    eval $port_variable_name="$port"

    export "$host_variable_name"
    export "$port_variable_name"
  fi
}

# Remove pid
rm -f /home/appmaster/application/unicorn.pid

set_address_and_port "DATABASE_HOST" "DATABASE_PORT" "$DATABASE_AVZONE" "POSTGRESQL_MASTER"
echo "setting DATABASE_HOST=$DATABASE_HOST"
echo "setting DATABASE_PORT=$DATABASE_PORT"

# Copy original public files to public folder
cp -Rp /home/appmaster/application/public_original/* /home/appmaster/application/public/

echo "precompiling..."
bundle exec rake assets:precompile

echo "migrating database..."
bundle exec rake db:create db:migrate

echo "starting application as webserver..."
exec bundle exec unicorn_rails -c /home/appmaster/application/config/unicorn.rb

