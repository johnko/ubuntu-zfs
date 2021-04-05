#!/usr/bin/env bash
set -e
set -x

# Ubuntu 18.04 uses netplan, but for now we still want ifupdown to email us about IP changes
apt-get install --yes ifupdown

OUTFILE="/etc/network/interfaces"
SOURCEDIR="/etc/network/interfaces.d"

if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi

cat >"${OUTFILE}" <<EOF
source ${SOURCEDIR}/*
EOF

# Only manipulate /etc/network/interfaces.d/ for 16.04
if lsb_release -r | grep -q "16.04"; then
  if [ ! -f "${SOURCEDIR}/lo" ]; then
    cat >"${SOURCEDIR}/lo" <<EOF
auto lo
iface lo inet loopback
EOF
  fi

  ACTIVE_NICS=$(ip link | grep '^[0-9]' | grep -E -v '(^docker| lo:|NO-CARRIER)' | cut -d' ' -f2 | cut -d: -f1)
  for i in ${ACTIVE_NICS}; do
    if [ ! -f "${SOURCEDIR}/${i}" ]; then
      cat >"${SOURCEDIR}/${i}" <<EOF
auto ${i}
iface ${i} inet dhcp
EOF
    fi
  done

  UNPLUG_NICS=$(ip link | grep '^[0-9]' | grep 'NO-CARRIER' | cut -d' ' -f2 | cut -d: -f1)
  for i in ${UNPLUG_NICS}; do
    if [ ! -f "${SOURCEDIR}/${i}" ]; then
      cat >"${SOURCEDIR}/${i}" <<EOF
#auto ${i}
#iface ${i} inet dhcp
EOF
    fi
  done
fi

install -d -m 755 -o root -g root /etc/netplan
cat >>/etc/netplan/01-network-manager-all.yaml <<EOF
# Let NetworkManager manage all devices on this system
network:
  version: 2
  renderer: NetworkManager
EOF
chown root: /etc/netplan/01-network-manager-all.yaml
chmod 644 /etc/netplan/01-network-manager-all.yaml

# example wifi managed by NetworkManager
install -d -m 755 -o root -g root /etc/NetworkManager
install -d -m 755 -o root -g root /etc/NetworkManager/system-connections
cat >>/etc/NetworkManager/system-connections/xxxxxxx <<EOF
[connection]
id=xxxxxxx
uuid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
type=wifi
permissions=

[wifi]
mac-address=xx:xx:xx:xx:xx:xx
mac-address-blacklist=
mode=infrastructure
ssid=xxxxxxx

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

[ipv4]
dns-search=
method=auto

[ipv6]
addr-gen-mode=stable-privacy
dns-search=
method=auto
EOF
chown root: /etc/NetworkManager/system-connections/xxxxxxx
chmod 600 /etc/NetworkManager/system-connections/xxxxxxx

# How to use nmcli to connect to wifi
#nmcli dev wifi list
#nmcli dev wifi con mySSID password myPassword
#nmcli con down mySSID
#nmcli con up mySSID
#nmcli con delete mySSID
#ip link set down wlx0
#ip link set up wlx0
#ip addr

# Temporary give wifi route higher priority
#ip route add $(ip route | grep 'default.*wlx' | awk '{$NF=50;print}')
