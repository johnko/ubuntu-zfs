#!/usr/bin/env bash
set -e
#set -x

# Based on https://gist.github.com/petervanderdoes/bd6660302404ed5b094d

# 691200 seconds is 8 days
MAXAGE=691200

NOW=$(date +%s)

# only scrub healthy pools based on /usr/lib/zfs-linux/scrub
POOLS=$(zpool list -o name,health -H | awk '$2~/^ONLINE/ {print $1}')
for i in ${POOLS}; do
  if zpool status "${i}" | grep -q "none requested"; then
    zpool scrub "${i}"
  elif zpool status "${i}" | grep -E -q "(scrub in progress|resilver)"; then
    echo "Scrub already in progress for ${i}"
  else
    LASTSCRUB_DATE=$(zpool status "${i}" | grep scrub | awk '{print $11" "$12" " $13" " $14" "$15}')
    LASTSCRUB=$(date -d "${LASTSCRUB_DATE}" +%s)
    if [ $((NOW - LASTSCRUB)) -ge $MAXAGE ]; then
      zpool scrub "${i}"
    fi
  fi
done
