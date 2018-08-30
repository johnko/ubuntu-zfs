#!/usr/bin/env bash
set -e
set -x

. ./env.sh

chmod go-rwx ./env.sh

if [ -z "${ZFS_ROOT_POOL}" ]; then
  ZFS_ROOT_POOL=system
fi

TARGET="/target"

umount -l "${TARGET}/dev"
umount -l "${TARGET}/proc"
umount -l "${TARGET}/sys"

zpool destroy "${ZFS_ROOT_POOL}" || true
if [ -n "${ZFS_DATA_POOL}" ]; then
  zpool destroy "${ZFS_DATA_POOL}" || true
fi

./install.sh

