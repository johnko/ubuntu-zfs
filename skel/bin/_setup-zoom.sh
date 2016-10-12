#!/usr/bin/env bash
set -e
set -x

#exit if no desktop installed
dpkg -l | grep ubuntu-desktop || exit 0

sudo apt-get install --yes libxcb-xtest0

if ! which zoom; then
  FILE=zoom_amd64.deb
  mkdir -p "${HOME}/.apt-cache"
  [ ! -e "${HOME}/.apt-cache/${FILE}" ] && curl -o "${HOME}/.apt-cache/${FILE}" -L "https://zoom.us/client/latest/${FILE}"
  sudo dpkg -i "${HOME}/.apt-cache/${FILE}"
fi
