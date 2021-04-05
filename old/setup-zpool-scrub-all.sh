#!/usr/bin/env bash
set -e
set -x

if [ -z "${PREFIX}" ]; then
  PREFIX=/usr/local
fi

install -d /etc/cron.d
install -m 0644 zpool-scrub-all.cron.frequent /etc/cron.d/zpool-scrub-all
sed -i -e "s:zpool-scrub-all:${PREFIX}/sbin/zpool-scrub-all:g" /etc/cron.d/zpool-scrub-all
install -d "${PREFIX}/sbin"
install zpool-scrub-all.sh "${PREFIX}/sbin/zpool-scrub-all"
# disable /usr/lib/zfs-linux/scrub
chmod -x /usr/lib/zfs-linux/scrub

if [ -n "${GMAIL_USER}" ]; then
  sed -i -e "s:^MAILTO=.*:MAILTO=${GMAIL_USER}:g" /etc/cron.d/zpool-scrub-all
fi
