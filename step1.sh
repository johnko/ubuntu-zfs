#!/usr/bin/env bash
set -exuo pipefail

# Step 1.2 Update the apt repo:
apt-get update

# Sync time
# apt-get install --yes ntpdate
# ntpdate pool.ntp.org

# Step 1.6 Install ZFS in the Live CD environment:
apt-get install --yes debootstrap gdisk zfs-initramfs
systemctl stop zed
