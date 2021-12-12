#!/bin/sh

set -e

output=$2
input=$1

ffmpeg -i "$input" -movflags use_metadata_tags -c:v libx264 -c:a copy "$output" # -crf 21
date=$(exiftool -J "$input"  | jq -r '.[] | .ModifyDate')
echo "date: $date"

exiftool -overwrite_original "-ModifyDate=$date" "$output"
