#!/usr/bin/env bash
set -e
set -x

cd /root/ubuntu-zfs

. ./env.sh

if [[ -z "${NEWHOSTNAME}" ]]; then
  NEWHOSTNAME=unassigned-hostname
fi

OUTFILE="/etc/postfix/main.cf"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
install -m 644 main.cf.local "${OUTFILE}"
sed -i "s;unassigned-hostname;${NEWHOSTNAME};" "${OUTFILE}"

newaliases
