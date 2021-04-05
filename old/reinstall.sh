#!/usr/bin/env bash
set -e
set -x

. ./env.sh

chmod go-rwx ./env.sh

if [ -z "${ZFS_ROOT_POOL}" ]; then
  ZFS_ROOT_POOL=system
fi

TARGET="/target"

umount -l "${TARGET}/dev" || true
umount -l "${TARGET}/proc" || true
umount -l "${TARGET}/sys" || true

zpool destroy "${ZFS_ROOT_POOL}" || true
if [ -n "${ZFS_DATA_POOL}" ]; then
  zpool destroy "${ZFS_DATA_POOL}" || true
fi

./install.sh
