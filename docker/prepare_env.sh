#!/bin/sh

set -e

docker pull ruby:${DOCKER_RUBY_VERSION}-alpine
docker pull postgres:${POSTGRES_IMAGE_TAG}-alpine
docker pull redis:${REDIS_IMAGE_TAG}-alpine
docker pull golang:${DOCKER_GO_VERSION}-alpine
docker pull golang:${DOCKER_GO_VERSION}

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
