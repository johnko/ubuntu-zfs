#!/usr/bin/env bash
set -e
set -x

# Wait for network
while ! ping -c 1 github.com; do
  sleep 1
done

git clone https://github.com/johnko/zfs-auto-snapshot.git
cd zfs-auto-snapshot
./install.sh
cd -
