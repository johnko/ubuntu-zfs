#!/usr/bin/env bash
set -e
set -x

cd /root/ubuntu-zfs

. ./env.sh

if [ -z "${NEWHOSTNAME}" ]; then
  NEWHOSTNAME=unassigned-hostname
fi

BACKUPDIR="/root/${NEWHOSTNAME}"
if [ ! -d "${BACKUPDIR}" ]; then
  install -d -m 700 "${BACKUPDIR}"
  (
    cd "${BACKUPDIR}"
    git init
  )
fi

cd "${BACKUPDIR}"

git config user.name root
git config user.email "root@${NEWHOSTNAME}"

if find / -name "*.original" 2>/dev/null | grep -v " " | grep -v "newt/palette.original"; then
  ORIGINALS=$(find / -name "*.original" 2>/dev/null | grep -v " " | grep -v "newt/palette.original")
  for i in ${ORIGINALS}; do
    ORIG_NAME="${i}"
    BKP_NAME=".${ORIG_NAME%.original}"
    ORIG_DIR=$(dirname "${BKP_NAME}")
    if [ ! -d "${ORIG_DIR}" ]; then
      install -d -m 700 "${ORIG_DIR}"
    fi
    mv "${ORIG_NAME}" "${BKP_NAME}"
    git add "${BKP_NAME}"
    git commit -m "${BKP_NAME} $(date -u +%Y%m%d-%H%M%S-%Z)"
  done
fi

if find "${BACKUPDIR}" -type f 2>/dev/null | grep -v " " | grep -v "/.git/"; then
  TRACKED=$(find "${BACKUPDIR}" -type f 2>/dev/null | grep -v " " | grep -v "/.git/")
  for i in ${TRACKED}; do
    ORIG_NAME=$(echo "${i}" | sed "s;${BACKUPDIR};;")
    BKP_NAME=$(echo "${i}" | sed "s;${BACKUPDIR};.;")
    if ! diff -q "${ORIG_NAME}" "${BKP_NAME}"; then
      cp -a "${ORIG_NAME}" "${BKP_NAME}"
      git add "${BKP_NAME}"
      git commit -m "${BKP_NAME} $(date -u +%Y%m%d-%H%M%S-%Z)"
    fi
  done
fi

cd -
