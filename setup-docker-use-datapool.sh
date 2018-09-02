#!/usr/bin/env bash
set -e
set -x

. ./env.sh

if [ -z "${ZFS_ROOT_POOL}" ]; then
  ZFS_ROOT_POOL=system
fi
if [ -n "${ZFS_DATA_POOL}" ]; then
  systemctl stop docker
  zfs set mountpoint=/var/lib/docker2 "${ZFS_ROOT_POOL}/docker"
  zfs create -o mountpoint=/var/lib/docker "${ZFS_DATA_POOL}/docker"
  systemctl start docker
  zfs destroy -r "${ZFS_ROOT_POOL}/docker"
fi
