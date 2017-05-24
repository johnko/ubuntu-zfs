#!/usr/bin/env bash
set -e
set -x

TMPFS="/var/lib/docker"
DISKMOUNT="/var/lib/2docker"
ZFSSET="system/docker"

function start_dtmpfs() {
  # Start using tmpfs for docker, copy all containers and images to tmpfs
  sudo service docker stop
  # if using zfs, set mountpoint old old docker dataset
  sudo zfs list "${ZFSSET}" && sudo zfs set "mountpoint=${DISKMOUNT}" "${ZFSSET}"
  # mount tmpfs
  [ ! -e "${TMPFS}" ] && sudo mkdir -p "${TMPFS}"
  mount | grep "${TMPFS}" || sudo mount -t tmpfs tmpfs "${TMPFS}"
  mount | grep "${TMPFS}" | grep "tmpfs" || exit 1
  # copy docker files from disk to tmpfs
  [ -e "${DISKMOUNT}" ] && sudo rsync -vialP "${DISKMOUNT}/" "${TMPFS}/"
  sudo service docker start
}

function stop_dtmpfs() {
  # Stop using tmpfs for docker, lose all containers and images
  sudo service docker stop
  # unmount tmpfs
  mount | grep "${TMPFS}" | grep "tmpfs" && sudo umount "${TMPFS}"
  mount | grep "${TMPFS}" | grep "tmpfs" && exit 1
  # if using zfs, set mountpoint
  sudo zfs list "${ZFSSET}" && sudo zfs set "mountpoint=${TMPFS}" "${ZFSSET}"
  sudo service docker start
}

function bkp_dtmpfs() {
  # Backup all containers and images from tmpfs to DISKMOUNT
  sudo service docker stop
  # copy docker files from disk to tmpfs
  [ -e "${DISKMOUNT}" ] && sudo rsync -vialP "${TMPFS}/" "${DISKMOUNT}/"
  sudo service docker start
}

case "${1}" in
  stop)
    stop_dtmpfs
    ;;
  bkp | backup)
    bkp_dtmpfs
    ;;
  *)
    start_dtmpfs
    ;;
esac
