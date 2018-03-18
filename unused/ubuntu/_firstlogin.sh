#!/usr/bin/env bash
set -e
set -x

_disable-automount.sh
_screensaver-disable.sh
_setup-sudoers.sh
_ssh-keygen.sh

for i in "${HOME}/bin/docker-compose"-*; do
  ln -sf ${i} "${HOME}/bin/docker-compose"
done

# Wait for network
while ! ping -c 1 archive.ubuntu.com; do
  sleep 1
done

_setup-golang.sh
for i in "${HOME}/bin/_setup"-*; do
  "${i}"
done

#glances.sh
_backup-apt-cache.sh
