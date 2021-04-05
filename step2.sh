#!/usr/bin/env bash
set -exuo pipefail

# Step 2.2 If you are re-using a disk, clear it as necessary:
apt-get install --yes mdadm
for i in $DISKS; do
  mdadm --zero-superblock --force $i
  sgdisk --zap-all $i
done

SIZE=0
for i in $DISKS; do
  (
    echo g  # g for new gpt table
    echo p  # p for print
    echo w  # w for write
  ) | fdisk $i
done

BOOT_VDEVS=""
RPOOL_VDEVS=""
ZDATA_VDEVS=""
NUM_VDEVS=0
for i in $DISKS; do
  # Step 2.3 Create EFI bootloader partition(s):
  # sgdisk     -n1:1M:+512M   -t1:EF00 $i
  # For legacy (BIOS) booting:
  sgdisk -a1 -n1:1M:512M -t1:EF02 $i
  # Step 2.5 Create a boot pool partition:
  sgdisk -n2:0:+2G -t2:BE00 $i
  # Step 2.6 Create a root pool partition:
  if [ "$ZFS_ROOT_SIZE" != "0" ]; then
    # we have size, use it
    sgdisk -n3:0:+$ZFS_ROOT_SIZE -t3:BF00 $i
    # create another partition for zfs data pool
    if [ "$ZFS_DATA_SIZE" != "0" ]; then
      sgdisk -n4:0:+$ZFS_DATA_SIZE -t4:BF00 $i
    else
      sgdisk -n4:0:0 -t4:BF00 $i
    fi
  else
    # no size so use whole disk
    sgdisk -n3:0:0 -t3:BF00 $i
  fi
  BOOT_VDEVS="$BOOT_VDEVS ${i}2"
  RPOOL_VDEVS="$RPOOL_VDEVS ${i}3"
  ZDATA_VDEVS="$ZDATA_VDEVS ${i}4"
  NUM_VDEVS=$((NUM_VDEVS + 1))
done
sleep 5
zpool destroy $BOOT_POOL || true
zpool destroy $ZFS_ROOT_POOL || true
sleep 2
for i in $BOOT_VDEVS $RPOOL_VDEVS; do
  zpool labelclear -f $i || true
done
sleep 2

# detect single or mirror
if [ $NUM_VDEVS -gt 1 ]; then
  if [ -z "$ZFS_ROOT_ZRAID" ]; then
    ZFS_ROOT_ZRAID=mirror
  fi
else
  ZFS_ROOT_ZRAID=""
fi

# Step 2.7 Create the boot pool:
zpool create \
  -f \
  -o cachefile=/etc/zfs/zpool.cache \
  -o ashift=12 -o autotrim=on -d \
  -o feature@async_destroy=enabled \
  -o feature@bookmarks=enabled \
  -o feature@embedded_data=enabled \
  -o feature@empty_bpobj=enabled \
  -o feature@enabled_txg=enabled \
  -o feature@extensible_dataset=enabled \
  -o feature@filesystem_limits=enabled \
  -o feature@hole_birth=enabled \
  -o feature@large_blocks=enabled \
  -o feature@lz4_compress=enabled \
  -o feature@spacemap_histogram=enabled \
  -O acltype=posixacl -O canmount=off -O compression=lz4 \
  -O devices=off -O normalization=formD -O relatime=on -O xattr=sa \
  -O mountpoint=/boot -R $TARGET \
  $BOOT_POOL $ZFS_ROOT_ZRAID $BOOT_VDEVS

# Step 2.8 Create the root pool:
zpool create \
  -f \
  -o ashift=12 -o autotrim=on \
  -O acltype=posixacl -O canmount=off -O compression=lz4 \
  -O dnodesize=auto -O normalization=formD -O relatime=on \
  -O xattr=sa -O mountpoint=/ -R $TARGET \
  $ZFS_ROOT_POOL $ZFS_ROOT_ZRAID $RPOOL_VDEVS

# only create data pool if root was limited in size
if [ "$ZFS_ROOT_SIZE" != "0" ] && [ -n "$ZFS_DATA_POOL" ]; then
  # detect single or mirror
  if [ $NUM_VDEVS -gt 1 ]; then
    if [ -z "$ZFS_DATA_ZRAID" ]; then
      ZFS_DATA_ZRAID=mirror
    fi
  else
    ZFS_DATA_ZRAID=""
  fi
  if zpool status $ZFS_DATA_POOL; then
    if [ -z "$ZFS_DATA_DESTROY" ]; then
      echo "Destroy existing zpool ${ZFS_DATA_POOL}? [y/N]:"
      read ZFS_DATA_DESTROY
    fi
    case "$ZFS_DATA_DESTROY" in
    [yY])
      ZFS_DATA_DESTROY=Y
      ;;
    *)
      ZFS_DATA_DESTROY=N
      ;;
    esac
    if [ "$ZFS_DATA_DESTROY" = "Y" ]; then
      zpool destroy $ZFS_DATA_POOL || true
      sleep 2
      for i in $ZDATA_VDEVS; do
        zpool labelclear -f $i || true
      done
      sleep 2
    fi
  fi
  zpool create \
    -f \
    -o ashift=12 -o autotrim=on \
    -O acltype=posixacl -O canmount=off -O compression=lz4 \
    -O dnodesize=auto -O normalization=formD -O relatime=on \
    -O xattr=sa \
    $ZFS_DATA_POOL $ZFS_DATA_ZRAID $ZDATA_VDEVS
fi
