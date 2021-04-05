#!/usr/bin/env bash
set -exuo pipefail

OLD_UMASK=$(umask)
umask 0077
exec 1> >(tee /var/log/00-ubuntu-zfs-install.log)
exec 2>&1
umask $OLD_UMASK

# get environment variables
chmod a-x ./env.sh
chmod go-rw ./env.sh
source ./env.sh
export UBUNTU_CODENAME=$(lsb_release -c -s)
export DEBIAN_FRONTEND=noninteractive
export TARGET=/target
export UUID=$(dd if=/dev/urandom bs=1 count=100 2>/dev/null |
  tr -dc 'a-z0-9' | cut -c-6)

if [ -z "$BOOT_POOL" ]; then
  export BOOT_POOL=bpool
fi

if [ -z "$ZFS_ROOT_POOL" ]; then
  export ZFS_ROOT_POOL=system
fi

if [ -z "$ZFS_ROOT_SIZE" ]; then
  export ZFS_ROOT_SIZE=0
fi

if [ -z "$ZFS_DATA_SIZE" ]; then
  export ZFS_DATA_SIZE=0
fi

if [ "x" != "x${ZFS_ROOT_ZRAID}" ]; then
  case "$ZFS_ROOT_ZRAID" in
  "" | mirror | raidz | raidz1 | raidz2 | raidz3)
    echo "ZFS_ROOT_ZRAID: $ZFS_ROOT_ZRAID"
    ;;
  *)
    echo "ERROR: invalid env ZFS_ROOT_ZRAID" >&2
    exit 1
    ;;
  esac
fi

if [ "x" != "x${ZFS_DATA_ZRAID}" ]; then
  case "$ZFS_DATA_ZRAID" in
  "" | mirror | raidz | raidz1 | raidz2 | raidz3)
    echo "ZFS_DATA_ZRAID: $ZFS_DATA_ZRAID"
    ;;
  *)
    echo "ERROR: invalid env ZFS_DATA_ZRAID" >&2
    exit 1
    ;;
  esac
fi

# Step 1.4
gsettings set org.gnome.desktop.media-handling automount false

# Wait for network
while ! ping -c 1 archive.ubuntu.com; do
  sleep 1
done

sudo -E bash step1.sh
sudo -E bash step2.sh
sudo -E bash step3.sh
sudo -E bash step4.sh
sudo -E bash step6.3.sh
sudo bash step7.sh
sudo bash step8.sh
