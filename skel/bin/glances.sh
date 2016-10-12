#!/usr/bin/env bash
set -e
set -x

IMAGE_NAME=nicolargo/glances
CONTAINER_NAME=glances
NETWORK_OPT="-p 61208-61209:61208-61209"
NETWORK_OPT="--net host"

docker rm -f "${CONTAINER_NAME}" || true
docker pull "${IMAGE_NAME}"
docker run -d --restart=always ${NETWORK_OPT} -e GLANCES_OPT="-w" -v /etc/passwd:/etc/passwd:ro -v /var/run/docker.sock:/var/run/docker.sock:ro --pid host --name "${CONTAINER_NAME}" "${IMAGE_NAME}"

echo "visit http://localhost:61208/"
