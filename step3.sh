#!/usr/bin/env bash
set -exuo pipefail

# Step 3.1 Create filesystem datasets to act as containers:
zfs create -o canmount=off -o mountpoint=none "${ZFS_ROOT_POOL}/ROOT"
zfs create -o canmount=off -o mountpoint=none "${BOOT_POOL}/BOOT"

# Step 3.2 Create filesystem datasets for the root and boot filesystems:
zfs create -o mountpoint=/ \
  -o com.ubuntu.zsys:bootfs=yes \
  -o com.ubuntu.zsys:last-used=$(date +%s) "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}"

zfs create -o mountpoint=/boot "${BOOT_POOL}/BOOT/ubuntu_${UUID}"

# Step 3.3a Create datasets:
zfs create -o com.ubuntu.zsys:bootfs=no \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/srv"
zfs create -o com.ubuntu.zsys:bootfs=no -o canmount=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/usr"
zfs create "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/usr/local"
zfs create -o com.ubuntu.zsys:bootfs=no -o canmount=off \
  -o setuid=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var"
zfs create -o com.sun:auto-snapshot=false \
  -o exec=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/cache"
zfs create \
  -o exec=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/games"
zfs create "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/lib"
zfs create "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/lib/AccountsService"
zfs create \
  -o exec=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/lib/apt"
zfs create -o com.sun:auto-snapshot=false \
  -o exec=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/lib/docker"
zfs create "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/lib/dpkg"
zfs create "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/lib/NetworkManager"
zfs create -o com.sun:auto-snapshot=false \
  -o exec=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/lib/nfs"
zfs create \
  -o exec=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/log"
zfs create \
  -o exec=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/mail"
zfs create "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/snap"
zfs create \
  -o exec=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/spool"
zfs create \
  -o exec=off \
           "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/var/www"

zfs create -o canmount=off -o mountpoint=/ \
  -o setuid=off \
           "${ZFS_ROOT_POOL}/USERDATA"
zfs create -o com.ubuntu.zsys:bootfs-datasets=${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID} \
  -o canmount=on -o mountpoint=/root \
           "${ZFS_ROOT_POOL}/USERDATA/root_${UUID}"
chmod 700 ${TARGET}/root

# Step 3.3b For a mirror or raidz topology, create a dataset for /boot/grub:
NUM_VDEVS=0
for i in $DISKS; do
  NUM_VDEVS=$((NUM_VDEVS + 1))
done
# detect single or mirror
if [ $NUM_VDEVS -gt 1 ]; then
  if [ -z "$ZFS_ROOT_ZRAID" ]; then
    ZFS_ROOT_ZRAID=mirror
  fi
else
  ZFS_ROOT_ZRAID=""
fi
# Step 3.3b For a mirror or raidz topology, create a dataset for /boot/grub:
if [ "$ZFS_ROOT_ZRAID" == "mirror" ]; then
  zfs create -o com.ubuntu.zsys:bootfs=no "${BOOT_POOL}/grub"
fi

# Mount a tmpfs at /run:
mkdir ${TARGET}/run
mount -t tmpfs tmpfs ${TARGET}/run
mkdir ${TARGET}/run/lock

# Separate dataset for /tmp:
zfs create -o com.ubuntu.zsys:bootfs=no \
  -o com.sun:auto-snapshot=false -o exec=on \
  "${ZFS_ROOT_POOL}/ROOT/ubuntu_${UUID}/tmp"
chmod 1777 ${TARGET}/tmp

# Step 3.4 Install the minimal system:
debootstrap $UBUNTU_CODENAME $TARGET

# Step 3.5 Copy in zpool.cache:
mkdir ${TARGET}/etc/zfs
cp /etc/zfs/zpool.cache ${TARGET}/etc/zfs/
