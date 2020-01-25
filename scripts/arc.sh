#!/bin/bash

# backup script for db (script server)
# requires simple_gmail gem

set -e

project="photos"
pass="..."

fn="[$(date +"%Y_%m_%d-%H_%M_%S")]"
arc="$project-$(hostname)$fn"
dir="$HOME/arc/$arc"

if ! which rbenv > /dev/null
then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
  echo 'rbenv init'
fi

mkdir -p $dir
pg_dump --dbname="photos" --username=photos > "$dir/db.sql"
tar cfhJ "$dir/nginx.tar.xz" /etc/nginx
cp -f "$HOME/arc.sh" "$HOME/backup.rb" "$dir"
7za a -sdel -mhe=on -p"$pass" -mx9 "$HOME/arc/$arc.7z" "$dir" > /dev/null
ruby "$HOME/backup.rb"

echo 'ok'
