#!/usr/bin/env bash
set -e
set -x

OLD_UMASK=$(umask)
umask 0077
exec 1> >(tee /var/log/00-ubuntu-zfs-install.log)
exec 2>&1
umask "${OLD_UMASK}"

. ./env.sh

chmod go-rwx ./env.sh

if [ -z "${ZFS_ROOT_POOL}" ]; then
  ZFS_ROOT_POOL=system
fi

if [ "$(id -u)" != "0" ]; then
  cat <<EOF
#########################################
#  This script should be run with sudo  #
#########################################
EOF
  exit 1
fi

if [ -z "${DISKS}" ]; then
  echo "ERROR: missing env DISKS" >&2
  exit 1
fi

if [ -z "${UBUNTU_CODENAME}" ]; then
  echo "ERROR: missing env UBUNTU_CODENAME" >&2
  exit 1
fi

case "${INSTALL_TYPE}" in
  server | desktop)
    echo "INSTALL_TYPE: ${INSTALL_TYPE}"
    ;;
  *)
    echo "ERROR: invalid env INSTALL_TYPE" >&2
    exit 1
    ;;
esac

if [ "x" != "x${ZFS_ROOT_ZRAID}" ]; then
  case "${ZFS_ROOT_ZRAID}" in
    mirror | raidz | raidz1 | raidz2 | raidz3)
      echo "ZFS_ROOT_ZRAID: ${ZFS_ROOT_ZRAID}"
      ;;
    *)
      echo "ERROR: invalid env ZFS_ROOT_ZRAID" >&2
      exit 1
      ;;
  esac
fi

if [ "x" != "x${ZFS_DATA_ZRAID}" ]; then
  case "${ZFS_DATA_ZRAID}" in
    mirror | raidz | raidz1 | raidz2 | raidz3)
      echo "ZFS_DATA_ZRAID: ${ZFS_DATA_ZRAID}"
      ;;
    *)
      echo "ERROR: invalid env ZFS_DATA_ZRAID" >&2
      exit 1
      ;;
  esac
fi

TARGET="/target"

SIZE=0
for i in ${DISKS}; do
  SIZE=$(fdisk -l "${i}" | grep "Disk /dev/" | grep -o "[0-9][0-9]* bytes" | awk '{print $1}')
  if [ ${SIZE} -gt 2199023255040 ]; then
    # g for new gpt table
    # p for print
    # w for write
    (
      echo g
      echo p
      echo w
    ) | fdisk "${i}"
  else
    if [ -n "${ZFS_ROOT_SIZE}" ]; then
      # we have a size
      (
        echo o                   # new dos table
        echo n                   # new partition
        echo p                   # primary partition
        echo 1                   # select partition 1
        echo                     # default sector start
        echo "+${ZFS_ROOT_SIZE}" # +100G size
        echo t                   # change type
        echo bf                  # select bf type
        echo a                   # active/bootable part
        echo n                   # new partition
        echo p                   # primary partition
        echo 2                   # select partition 2
        echo                     # default sector start
        echo +1M                 # +1M size
        echo t                   # change type
        echo 2                   # select partition 2
        echo 0                   # select 0 type
        echo n                   # new partition
        echo p                   # primary partition
        echo 3                   # select partition 3
        echo                     # default sector start
        echo                     # default all size
        echo t                   # change type
        echo 3                   # select partition 3
        echo bf                  # select bf type
        echo p                   # p for print table
        echo w                   # w for write table
      ) | fdisk "${i}"
    else
      # no size, so use whole disk
      (
        echo o  # new dos table
        echo n  # new partition
        echo p  # primary partition
        echo 1  # select partition 1
        echo    # default sector start
        echo    # default all size
        echo t  # change type
        echo bf # select bf type
        echo a  # active/bootable part
        echo p  # print table
        echo w  # write table
      ) | fdisk "${i}"
    fi
  fi
done

if [ -n "${RSYNC_CACHE_SERVER}" ]; then
  rsync -virtP --exclude lock --exclude partial --exclude .DS_Store "${RSYNC_CACHE_SERVER}/" /root/.apt-cache/
  install -d -m 755 /var/lib
  install -d -m 755 /var/lib/apt
  install -d -m 755 /var/lib/apt/lists
  install -d -m 755 /var/cache
  install -d -m 755 /var/cache/apt
  install -d -m 755 /var/cache/apt/archives
  rsync -virtP --exclude lock --exclude partial /root/.apt-cache/lists/ /var/lib/apt/lists/
  rsync -virtP --exclude lock --exclude partial /root/.apt-cache/apt/ /var/cache/apt/
  rm -fr /root/.apt-cache/lists
  rm -fr /root/.apt-cache/apt
fi

# Wait for network
while ! ping -c 1 archive.ubuntu.com; do
  sleep 1
done

# Get ZFS packages
apt-add-repository universe
if [ -z "${RSYNC_CACHE_SERVER}" ]; then
  apt-get update
fi
apt-get install --yes debootstrap gdisk zfs-initramfs mdadm

# Sync time
apt-get install --yes ntpdate
ntpdate pool.ntp.org

ZPOOL_VDEVS=""
ZDATA_VDEVS=""
SIZE=0
NUM_VDEVS=0
for i in ${DISKS}; do
  mdadm --zero-superblock --force "${i}"
  SIZE=$(fdisk -l "${i}" | grep "Disk /dev/" | grep -o "[0-9][0-9]* bytes" | awk '{print $1}')
  if [ ${SIZE} -gt 2199023255040 ]; then
    sgdisk -a1 -n2:1M:512M -t2:EF02 "${i}"
    sgdisk -n9:-8M:0 -t9:BF07 "${i}"
    if [ -n "${ZFS_ROOT_SIZE}" ]; then
      # we have size, use it
      sgdisk -n1:0:${ZFS_ROOT_SIZE} -t1:BF01 "${i}"
      # create another partition for zfs data pool
      sgdisk -n3:0:0 -t3:BF01 "${i}"
    else
      # no size so use whole disk
      sgdisk -n1:0:0 -t1:BF01 "${i}"
    fi
  fi
  ZPOOL_VDEVS="${ZPOOL_VDEVS} ${i}1"
  ZDATA_VDEVS="${ZDATA_VDEVS} ${i}3"
  NUM_VDEVS=$((NUM_VDEVS + 1))
done
sleep 5
zpool destroy "${ZFS_ROOT_POOL}" || true
sleep 2
for i in ${ZPOOL_VDEVS}; do
  zpool labelclear "${i}" || true
done
sleep 2

# detect single or mirror
if [ ${NUM_VDEVS} -gt 1 ]; then
  if [ -z "${ZFS_ROOT_ZRAID}" ]; then
    ZFS_ROOT_ZRAID=mirror
  fi
else
  ZFS_ROOT_ZRAID=""
fi
zpool create -f -o ashift=12 \
  -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
  -O mountpoint=/ -R "${TARGET}" \
  "${ZFS_ROOT_POOL}" ${ZFS_ROOT_ZRAID} ${ZPOOL_VDEVS}

zfs create -o canmount=off -o mountpoint=none "${ZFS_ROOT_POOL}/ROOT"
zfs create -o canmount=noauto -o mountpoint=/ "${ZFS_ROOT_POOL}/ROOT/ubuntu"
zfs mount "${ZFS_ROOT_POOL}/ROOT/ubuntu"
zfs create -o setuid=off "${ZFS_ROOT_POOL}/home"
zfs create -o mountpoint=/root "${ZFS_ROOT_POOL}/home/root"
zfs create -o canmount=off -o setuid=off -o exec=off "${ZFS_ROOT_POOL}/var"
zfs create -o com.sun:auto-snapshot=false "${ZFS_ROOT_POOL}/var/cache"
#zfs create                                            "${ZFS_ROOT_POOL}/var/log"
zfs create "${ZFS_ROOT_POOL}/var/spool"
zfs create -o com.sun:auto-snapshot=false -o exec=on "${ZFS_ROOT_POOL}/var/tmp"
#zfs create                                            "${ZFS_ROOT_POOL}/srv"
zfs create "${ZFS_ROOT_POOL}/var/games"
zfs create "${ZFS_ROOT_POOL}/var/mail"
zfs create -o mountpoint=/var/lib/docker "${ZFS_ROOT_POOL}/docker"
zfs create -o com.sun:auto-snapshot=false \
  -o mountpoint=/var/lib/nfs "${ZFS_ROOT_POOL}/var/nfs"

# only create data pool if root was limited in size
if [ -n "${ZFS_DATA_POOL}" ] && [ -n "${ZFS_ROOT_SIZE}" ]; then
  # detect single or mirror
  if [ ${NUM_VDEVS} -gt 1 ]; then
    if [ -z "${ZFS_DATA_ZRAID}" ]; then
      ZFS_DATA_ZRAID=mirror
    fi
  else
    ZFS_DATA_ZRAID=""
  fi
  if zpool status "${ZFS_DATA_POOL}"; then
    if [ -z "${ZFS_DATA_DESTROY}" ]; then
      echo "Destroy existing zpool ${ZFS_DATA_POOL}? [y/N]:"
      read ZFS_DATA_DESTROY
    fi
    case "${ZFS_DATA_DESTROY}" in
      [yY])
        ZFS_DATA_DESTROY=Y
        ;;
      *)
        ZFS_DATA_DESTROY=N
        ;;
    esac
    if [ "${ZFS_DATA_DESTROY}" = "Y" ]; then
      zpool destroy "${ZFS_DATA_POOL}" || true
      sleep 2
      for i in ${ZDATA_VDEVS}; do
        zpool labelclear "${i}" || true
      done
      sleep 2
    fi
  fi
  zpool create -f -o ashift=12 \
    -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
    "${ZFS_DATA_POOL}" ${ZFS_DATA_ZRAID} ${ZDATA_VDEVS}
fi

chmod 1777 "${TARGET}/var/tmp"

install -d -m 755 "${TARGET}/var/lib"
install -d -m 755 "${TARGET}/var/lib/apt"
install -d -m 755 "${TARGET}/var/lib/apt/lists"
rsync -virtP --exclude lock --exclude partial /var/lib/apt/lists/ "${TARGET}/var/lib/apt/lists/"
install -d -m 755 "${TARGET}/var/cache"
install -d -m 755 "${TARGET}/var/cache/apt"
install -d -m 755 "${TARGET}/var/cache/apt/archives"
rsync -virtP --exclude lock --exclude partial /var/cache/apt/ "${TARGET}/var/cache/apt/"
[ -e /root/.apt-cache ] && mv /root/.apt-cache "${TARGET}/root/.apt-cache"

debootstrap "${UBUNTU_CODENAME}" "${TARGET}"
zfs set devices=off "${ZFS_ROOT_POOL}"

mount --rbind /dev "${TARGET}/dev"
mount --rbind /proc "${TARGET}/proc"
mount --rbind /sys "${TARGET}/sys"

cp -a ./ "${TARGET}/root/ubuntu-zfs"

chroot "${TARGET}" /root/ubuntu-zfs/system-setup.sh

cat <<EOF
###################
#  End of script  #
###################
EOF

cp -a /var/log/00-ubuntu-zfs-install.log "${TARGET}/var/log/00-ubuntu-zfs-install.log"

sync

mount | grep -v zfs | tac | awk "/\\${TARGET}/ {print \$3}" | xargs -i{} umount -lf {}
zpool export "${ZFS_ROOT_POOL}"

sync

if mount | grep -q "/cdrom" ; then
  umount -l /cdrom || true
fi

reboot -f
