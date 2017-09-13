#!/usr/bin/env bash
set -e
set -x

if [ -z "$DOCKER_HOST" ]; then
  . ~/docker-machine-env.sh
fi

IMAGE="registry.access.redhat.com/rhel7:7.4-105"
IMAGE="ubuntu:16.04"

docker run --rm --interactive --tty --volume ~/sync:/root/sync ${IMAGE} bash
