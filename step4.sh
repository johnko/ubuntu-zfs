#!/usr/bin/env bash
set -exuo pipefail

# Step 4.1 Configure the hostname:
echo "$NEW_HOSTNAME" > ${TARGET}/etc/hostname
echo "127.0.1.1       $NEW_HOSTNAME" >> ${TARGET}/etc/hosts

# Step 4.2 Configure the network interface:
IFACE=$( ip addr show up | grep BROADCAST | cut -d' ' -f2 | tr -d ':' )
cat > ${TARGET}/etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  ethernets:
    ${IFACE}:
      dhcp4: true
EOF

# Step 4.3 Configure the package sources:
cat > ${TARGET}/etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu focal-security main restricted universe multiverse
EOF

# Step 4.4 Bind the virtual filesystems from the LiveCD environment to the new system and chroot into it:
mount --rbind /dev  ${TARGET}/dev
mount --rbind /proc ${TARGET}/proc
mount --rbind /sys  ${TARGET}/sys

cp step4.5_to_6_chroot.sh ${TARGET}/
chmod +x ${TARGET}/step4.5_to_6_chroot.sh
chroot ${TARGET} /usr/bin/env \
  DISKS="$DISKS" \
  BOOT_POOL="$BOOT_POOL" \
  ZFS_ROOT_POOL="$ZFS_ROOT_POOL" \
  UUID="$UUID" \
  bash /step4.5_to_6_chroot.sh
