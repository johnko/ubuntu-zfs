#!/usr/bin/env bash
set -e
set -x

_disable-automount.sh
_setup-sudoers.sh

# Wait for network
while ! ping -c 1 archive.ubuntu.com; do
  sleep 1
done

_setup-golang.sh
for i in ~/bin/_setup-*; do
  "${i}"
done
#_docker-tmpfs.sh
#glances.sh
_backup-apt-cache.sh
