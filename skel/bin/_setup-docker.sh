#!/usr/bin/env bash
set -e
set -x

which docker || sudo apt-get install --yes docker.io

DOCKER_IMAGES="
rancher/server
nicolargo/glances
"

for i in ${DOCKER_IMAGES}; do
  docker pull "${i}"
done
