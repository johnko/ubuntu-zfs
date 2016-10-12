#!/usr/bin/env bash
set -e
set -x

IMAGE_NAME=rancher/server
CONTAINER_NAME=rancher_server
NETWORK_OPT="-p 8080:8080"

docker rm -f "${CONTAINER_NAME}" || true
docker pull "${IMAGE_NAME}"
docker run -d --restart=always ${NETWORK_OPT} --name "${CONTAINER_NAME}" "${IMAGE_NAME}"

echo "visit http://localhost:8080/"
