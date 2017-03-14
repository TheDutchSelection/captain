#!/bin/bash
set -e

# include dependencies
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/captain_functions"

run_script () {
  local current_time=$(date +"%H:%M")
  local tar_path="/backup/"
  
  mkdir -p "$tar_path"
  
  echo "current time: $current_time"
  echo "waiting for execution time $EXECUTION_TIME to backup volume $VOLUME..."

  while true; do
    sleep 45

    local current_time=$(date +"%H:%M")
    if [[ "$current_time" == "$EXECUTION_TIME" ]]; then
      local time_stamp=$(date +"%Y-%m-%d-%H-%M-%S")
      local tar_file="$TAR_BASE_FILENAME""_""$time_stamp"".tar"
      local old_tar_file_with_path="$tar_file_with_path"
      local tar_file_with_path="$tar_path$tar_file"

      echo "backup volume $VOLUME to $tar_file_with_path..."
      tar cvf "$tar_file_with_path" "$VOLUME"

      if [[ ! -z "$AWS_S3_ACCESS_KEY_ID" ]]; then
        if [[ ! -z "$old_tar_file_with_path" ]]; then
          echo "removing old local backup file $old_tar_file_with_path..."
          rm -f "$old_tar_file_with_path"
        fi

        echo "sending $tar_file_with_path to AWS S3 bucket $AWS_S3_BUCKET_NAME on path $AWS_S3_PATH..."
        export AWS_DEFAULT_REGION="$AWS_S3_BUCKET_REGION"
        export AWS_ACCESS_KEY_ID="$AWS_S3_ACCESS_KEY_ID"
        export AWS_SECRET_ACCESS_KEY="$AWS_S3_SECRET_ACCESS_KEY"
        /root/.local/bin/aws s3 cp "$tar_file_with_path" s3://"$AWS_S3_BUCKET_NAME"/"$AWS_S3_PATH"
      fi
    fi
  done
}

run_script &

wait
