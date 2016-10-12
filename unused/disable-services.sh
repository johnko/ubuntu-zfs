#!/usr/bin/env bash
set -e
set -x

SERVICES="
avahi-daemon
avahi-daemon.socket
"
while netstat -pan | grep -q "avahi"; do
  for i in ${SERVICES}; do
    systemctl stop "${i}" || true
    systemctl disable "${i}" || true
  done
  sleep 2
done

SERVICES="
cups
cups.path
cups.socket
cups-browsed
"
while netstat -pan | grep -q "cups"; do
  for i in ${SERVICES}; do
    systemctl stop "${i}" || true
    systemctl disable "${i}" || true
  done
  sleep 2
done

SERVICES="
snapd
snapd.socket
"
while netstat -pan | grep -q "snapd"; do
  for i in ${SERVICES}; do
    systemctl stop "${i}" || true
    systemctl disable "${i}" || true
  done
  sleep 2
done
