#!/bin/sh

docker build -t jqarmv7-builder . &&  docker run -v "$PWD":/app/ready jqarmv7-builder
