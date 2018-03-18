#!/usr/bin/env bash
set -e
set -x

. "${HOME}/.env.sh"

mkdir -p "${HOME}/.apt-cache/apt/archives"
rsync -virtP --exclude lock --exclude partial /var/lib/apt/lists/ "${HOME}/.apt-cache/lists/"
rsync -virtP --exclude lock --exclude partial /var/cache/apt/ "${HOME}/.apt-cache/apt/"
cd "${HOME}/.apt-cache/apt/archives"
# dpkg -l | awk '$1~/ii/{print "apt-get download "$2}' | sh -x
apt list --installed 2>/dev/null | awk -F/ '{print "apt-get download "$1}' | sh -x
cd -

if [ -n "${RSYNC_CACHE_SERVER}" ]; then
  rsync -virtP --exclude lock --exclude partial "${HOME}/.apt-cache/" "${RSYNC_CACHE_SERVER}/"
fi
