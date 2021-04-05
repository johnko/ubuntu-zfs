#!/usr/bin/env bash
set -exuo pipefail

# Step 6.3 Run these commands in the LiveCD environment to unmount all filesystems:
mount | grep -v zfs | tac | awk "/\\${TARGET}/ {print \$3}" | \
  xargs -i{} umount -lf {}
zpool export -a
