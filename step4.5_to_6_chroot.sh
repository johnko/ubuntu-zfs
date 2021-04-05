#!/usr/bin/env bash
set -exuo pipefail

# Step 4.5 Configure a basic system environment:
apt-get update

# Even if you prefer a non-English system language, always ensure that en_US.UTF-8 is available:
dpkg-reconfigure locales tzdata keyboard-configuration console-setup

# Install your preferred text editor:
apt-get install --yes vim

# Step 4.7 Create the EFI filesystem:
# Perform these steps for both UEFI and legacy (BIOS) booting:
# apt-get install --yes dosfstools
# For a mirror or raidz topology, repeat the mkdosfs for the additional disks, but do not repeat the other commands.
# NUM_VDEVS=0
# for i in $DISKS; do
#   mkdosfs -F 32 -s 1 -n EFI ${i}1
#   NUM_VDEVS=$((NUM_VDEVS + 1))
#   if [ $NUM_VDEVS -eq 1 ]; then
#     mkdir /boot/efi
#     echo "/dev/${i}1 /boot/efi vfat defaults 0 0" >> /etc/fstab
#     mount /boot/efi
#   fi
# done

# Step 4.8 Put /boot/grub on the EFI System Partition: For a single-disk install only:
# This allows GRUB to write to /boot/grub (since it is on a FAT-formatted ESP instead of on ZFS), which means that /boot/grub/grubenv and the recordfail feature works as expected: if the boot fails, the normally hidden GRUB menu will be shown on the next boot. For a mirror or raidz topology, we do not want GRUB writing to the EFI System Partition. This is because we duplicate it at install without a mechanism to update the copies when the GRUB configuration changes (e.g. as the kernel is upgraded). Thus, we keep /boot/grub on the boot pool for the mirror or raidz topologies. This preserves correct mirroring/raidz behavior, at the expense of being able to write to /boot/grub/grubenv and thus the recordfail behavior.
# if [ $NUM_VDEVS -eq 1 ]; then
#   mkdir /boot/efi/grub /boot/grub
#   echo /boot/efi/grub /boot/grub none defaults,bind 0 0 >> /etc/fstab
#   mount /boot/grub
# fi

# Step 4.9 Install GRUB/Linux/ZFS in the chroot environment for the new system:

# Install GRUB/Linux/ZFS for legacy (BIOS) booting:
apt-get install --yes grub-pc linux-image-generic zfs-initramfs zsys

# Install GRUB/Linux/ZFS for UEFI booting:
# apt-get install --yes \
#     grub-efi-amd64 grub-efi-amd64-signed linux-image-generic \
#     shim-signed zfs-initramfs zsys

# Step 4.10 Optional: Remove os-prober:
apt-get remove --yes --purge os-prober

# Step 4.11 Set a root password:
( echo admin; echo admin; ) | passwd

# Step 4.14 Setup system groups:
addgroup --system lpadmin
addgroup --system lxd
addgroup --system sambashare

# Step 5.1 Verify that the ZFS boot filesystem is recognized:
grub-probe /boot

# Step 5.2 Refresh the initrd files:
update-initramfs -c -k all

# Step 5.3 Disable memory zeroing:
# Add init_on_alloc=0 to: GRUB_CMDLINE_LINUX_DEFAULT
# Remove quiet and splash from: GRUB_CMDLINE_LINUX_DEFAULT
if ! grep "^GRUB_CMDLINE_LINUX_DEFAULT.*init_on_alloc=0" /etc/default/grub ; then
  echo "GRUB_CMDLINE_LINUX_DEFAULT=\"init_on_alloc=0\"" >> /etc/default/grub
fi

# Step 5.4 Make debugging GRUB easier:
# Comment out: GRUB_TIMEOUT_STYLE=hidden
if ! grep "^GRUB_TIMEOUT_STYLE.*hidden" /etc/default/grub ; then
  echo "GRUB_TIMEOUT_STYLE=hidden" >> /etc/default/grub
fi
# Set: GRUB_TIMEOUT=5
if ! grep "^GRUB_TIMEOUT.*5" /etc/default/grub ; then
  echo "GRUB_TIMEOUT=5" >> /etc/default/grub
fi
# Below GRUB_TIMEOUT, add: GRUB_RECORDFAIL_TIMEOUT=5
if ! grep "^GRUB_RECORDFAIL_TIMEOUT.*5" /etc/default/grub ; then
  echo "GRUB_RECORDFAIL_TIMEOUT=5" >> /etc/default/grub
fi
# Uncomment: GRUB_TERMINAL=console
if ! grep "^GRUB_TERMINAL.*console" /etc/default/grub ; then
  echo "GRUB_TERMINAL=console" >> /etc/default/grub
fi

# Step 5.5 Update the boot configuration:
update-grub

# Step 5.6 Install the boot loader:

# For legacy (BIOS) booting, install GRUB to the MBR:
# Note that you are installing GRUB to the whole disk, not a partition.
# If you are creating a mirror or raidz topology, repeat the grub-install command for each disk in the pool.
NUM_VDEVS=0
for i in $DISKS; do
  grub-install $i
  NUM_VDEVS=$((NUM_VDEVS + 1))
done

# For UEFI booting, install GRUB to the ESP:
# grub-install --target=x86_64-efi --efi-directory=/boot/efi \
#     --bootloader-id=ubuntu --recheck --no-floppy

# Step 5.7 Disable grub-initrd-fallback.service
# This is the service for /boot/grub/grubenv which does not work on mirrored or raidz topologies. Disabling this keeps it from blocking subsequent mounts of /boot/grub if that mount ever fails.
# For a mirror or raidz topology:
if [ $NUM_VDEVS -gt 1 ]; then
  systemctl mask grub-initrd-fallback.service
fi

# Step 5.8 Fix filesystem mount ordering:
# We need to activate zfs-mount-generator. This makes systemd aware of the separate mountpoints, which is important for things like /var/log and /var/tmp. In turn, rsyslog.service depends on var-log.mount by way of local-fs.target and services using the PrivateTmp feature of systemd automatically use After=var-tmp.mount.
mkdir /etc/zfs/zfs-list.cache
touch /etc/zfs/zfs-list.cache/$BOOT_POOL
touch /etc/zfs/zfs-list.cache/$ZFS_ROOT_POOL
ln -s /usr/lib/zfs-linux/zed.d/history_event-zfs-list-cacher.sh /etc/zfs/zed.d
zed -F &

# Verify that zed updated the cache by making sure these are not empty:
export CACHE_IS_EMPTY=true
while [ "$CACHE_IS_EMPTY" == "true" ]; do
  zfs set canmount=on "${BOOT_POOL}/BOOT/ubuntu_$UUID"
  if [ $(cat /etc/zfs/zfs-list.cache/$BOOT_POOL | wc -c) -gt 0 ]; then
    export CACHE_IS_EMPTY=false
  fi
done
export CACHE_IS_EMPTY=true
while [ "$CACHE_IS_EMPTY" == "true" ]; do
  zfs set canmount=on "${ZFS_ROOT_POOL}/ROOT/ubuntu_$UUID"
  if [ $(cat /etc/zfs/zfs-list.cache/$ZFS_ROOT_POOL | wc -c) -gt 0 ]; then
    export CACHE_IS_EMPTY=false
  fi
done
# If either is empty, force a cache update and check again:
# If they are still empty, stop zed (as below), start zed (as above) and try again.

# Once the files have data, stop zed:
ZED_PROCESS=$(ps aux | grep zed | awk '{print $2}')
kill $ZED_PROCESS

# Fix the paths to eliminate /mnt:
sed -Ei "s|${TARGET}/?|/|" /etc/zfs/zfs-list.cache/*

# Step 6.1 Install SSH:
apt-get install --yes openssh-server
