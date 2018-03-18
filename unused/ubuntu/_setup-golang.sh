#!/usr/bin/env bash
set -e
set -x

VERSION=1.8.3

if ! which go; then
  FILE="go${VERSION}.linux-amd64.tar.gz"
  mkdir -p "${HOME}/.apt-cache"
  [ ! -e "${HOME}/.apt-cache/${FILE}" ] && curl -o "${HOME}/.apt-cache/${FILE}" -L "https://storage.googleapis.com/golang/${FILE}"
  sudo tar -C /usr/local -xzf "${HOME}/.apt-cache/${FILE}"
fi
