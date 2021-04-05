#!/usr/bin/env bash

export NEW_USER=admin
export NEW_HOSTNAME=fileserver.local

# disks to use for zfs root pool
export DISKS="/dev/sda /dev/sdb /dev/sdc /dev/sdd"

export BOOT_POOL=boot
export ZFS_ROOT_POOL=system
# zfs root raid usually is "" for 1 disk, mirror for more
export ZFS_ROOT_ZRAID=mirror
## 0 to use whole disk
export ZFS_ROOT_SIZE=100G

# comment to not create data pool
export ZFS_DATA_POOL=userdata
# zfs data raid can be "" for 1 disk, or for more disks: "", mirror, raidz, raidz2, raidz3
export ZFS_DATA_ZRAID=mirror
## 0 to use whole disk
export ZFS_DATA_SIZE=3000G
