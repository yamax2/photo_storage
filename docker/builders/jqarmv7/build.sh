#!/bin/sh

docker build -t jqarmv7-builder . &&  docker run --rm -v "$PWD":/app/ready jqarmv7-builder
