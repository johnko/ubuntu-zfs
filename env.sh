#!/usr/bin/env bash

export NEW_USER=admin
export NEW_HOSTNAME=temp.local

# disks to use for zfs root pool
export DISKS="/dev/sda /dev/sdb"

export BOOT_POOL=myboot
export ZFS_ROOT_POOL=mysystem
# zfs root raid usually is "" for 1 disk, mirror for more
export ZFS_ROOT_ZRAID=mirror
## 0 to use whole disk
export ZFS_ROOT_SIZE=6G

# comment to not create data pool
export ZFS_DATA_POOL=mydata
# zfs data raid can be "" for 1 disk, or for more disks: "", mirror, raidz, raidz2, raidz3
export ZFS_DATA_ZRAID=mirror
## 0 to use whole disk
export ZFS_DATA_SIZE=1G
