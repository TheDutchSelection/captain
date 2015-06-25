#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"
. "$dir/aws_s3_functions"

run_script () {
  local current_time=$(date +"%H:%M")
  local tar_path="/backup/"
  
  mkdir -p /backup
  
  echo "current time: $current_time"
  echo "waiting for execution time $EXECUTION_TIME to backup volume $DATA_CONTAINER_VOLUME..."

  while [[ true ]]; do
    sleep 45

    local current_time=$(date +"%H:%M")
    if [[ "$current_time" == "$EXECUTION_TIME" ]]; then
      local time_stamp=$(date +"%Y-%m-%d-%H-%M-%S")
      local tar_file="$TAR_BASE_FILENAME""_""$time_stamp"".tar"
      local old_tar_file_with_path="$tar_path$tar_file"
      local tar_file_with_path="$tar_path$tar_file"

      echo "backup volume $DATA_CONTAINER_VOLUME to $tar_file_with_path..."
      tar cvf "$tar_file_with_path" "$DATA_CONTAINER_VOLUME"

      if [[ ! -z "$AWS_S3_ACCESS_KEY_ID" ]]; then
        echo "removing old local backup file $old_tar_file_with_path..."
        rm -f "$old_tar_file_with_path"
        echo "sending $tar_file_with_path to AWS S3 bucket $AWS_S3_BUCKET_NAME on path $AWS_S3_PATH..."
        local aws_file="$AWS_S3_PATH""$tar_file"
        upload_to_aws_s3 "$AWS_S3_ACCESS_KEY_ID" "$AWS_S3_SECRET_ACCESS_KEY" "$AWS_S3_BUCKET_NAME" "$AWS_S3_BUCKET_REGION" "$aws_file" "$tar_file_with_path"
      fi
    fi
  done
}

run_script &

wait
