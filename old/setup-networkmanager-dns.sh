#!/usr/bin/env bash
set -e
set -x

OUTFILE="/etc/NetworkManager/NetworkManager.conf"
if [ -f "${OUTFILE}" ]; then
  sed -i 's;^dns=dnsmasq;#dns=dnsmasq;' "${OUTFILE}"
  #systemctl restart NetworkManager
fi
