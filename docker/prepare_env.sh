#!/bin/sh

set -e

for line in $(docker images -f "label=com.photo-storage.ruby.version" -q | uniq); do
  ver=$(docker inspect --format '{{ index .Config.Labels "com.photo-storage.ruby.version"}}' $line)

  if ! [ $ver = $DOCKER_RUBY_VERSION ]; then
    docker image rm --force $line
  fi
done

for line in $(docker images -f "label=com.photo-storage.go.version" -q | uniq); do
  ver=$(docker inspect --format '{{ index .Config.Labels "com.photo-storage.go.version"}}' $line)

  if ! [ $ver = $DOCKER_GO_VERSION ]; then
    docker image rm --force $line
  fi
done
