#!/usr/bin/env bash
set -e
set -x

VERSION=0.12.3

which vagrant || sudo apt-get install --yes vagrant

if [ ! -e /usr/bin/packer ]; then
  FILE="packer_${VERSION}_linux_amd64.zip"
  mkdir -p "${HOME}/.apt-cache"
  [ ! -e "${HOME}/.apt-cache/${FILE}" ] && curl -o "${HOME}/.apt-cache/${FILE}" -L "https://releases.hashicorp.com/packer/${VERSION}/${FILE}"
  unzip "${HOME}/.apt-cache/${FILE}"
  sudo mv packer /usr/bin/packer
fi
