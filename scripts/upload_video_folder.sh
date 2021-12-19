#!/bin/sh

# ./scripts/upload_video_folder.sh ~/Загрузки/sd/video_to_upload/ 177

set -e

FOLDER=$1
RUBRIC_ID=$2

if [ -z "$FOLDER" ]; then
  echo "folder required"
  exit 1
fi

if [ -z "$RUBRIC_ID" ]; then
  echo "rubric_id required"
  exit 1
fi


for file in $1*; do
  name=$(basename "$file")

  ./scripts/upload_video.rb "$file" "$RUBRIC_ID" "$name"
done
