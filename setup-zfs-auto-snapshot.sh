#!/usr/bin/env bash
set -e
set -x

# Wait for network
while ! ping -c 1 github.com; do
  sleep 1
done

git clone https://github.com/johnko/zfs-auto-snapshot.git
cd zfs-auto-snapshot
./install.sh
cd -

if [ -n "${GMAIL_USER}" ]; then
  for i in \
    /etc/cron.d/zfs-auto-snapshot \
    /etc/cron.hourly/zfs-auto-snapshot \
    /etc/cron.daily/zfs-auto-snapshot \
    /etc/cron.weekly/zfs-auto-snapshot \
    /etc/cron.monthly/zfs-auto-snapshot \
    ; do
    sed -i -e "s:^MAILTO=.*:MAILTO=${GMAIL_USER}:g" $i
  done
fi
