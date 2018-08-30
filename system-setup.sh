#!/usr/bin/env bash
set -e
set -x

OLD_UMASK=$(umask)
umask 0077
exec 1> >(tee /var/log/01-system-setup.log)
exec 2>&1
umask "${OLD_UMASK}"

cd /root/ubuntu-zfs

. ./env.sh

if [ -z "${NEWHOSTNAME}" ]; then
  NEWHOSTNAME=unassigned-hostname
fi
if [ -z "${ZFS_ROOT_POOL}" ]; then
  ZFS_ROOT_POOL=system
fi

if [ -z "${DISKS}" ]; then
  echo "ERROR: missing env DISKS" >&2
  exit 1
fi

#passwd

install -d -m 700 -o root -g root /root/.vim
install -d -m 700 -o root -g root /root/.vim/backups
install -d -m 700 -o root -g root /root/.vim/swaps
install -d -m 700 -o root -g root /root/.vim/undo
if [ -d /root/ubuntu-zfs/skel ]; then
  for i in /root/ubuntu-zfs/skel/.* /root/ubuntu-zfs/skel/*; do
    case ${i##*/} in
    . | ..)
      echo "Skipping ${i##*/}"
      ;;
    *)
      OUTFILE="/root/${i##*/}"
      if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
        cp -a "${OUTFILE}" "${OUTFILE}.original"
      fi
      [ -f "${i}" ] && install -m 600 -o root -g root "${i}" "${OUTFILE}"
      if [ -d "${i}" ]; then
        cp -a "${i}" /root
        chown -R root:root "${OUTFILE}"
        # remove group and other permissions
        find "${OUTFILE}" -exec chmod go-rwx {} \;
      fi
      ;;
    esac
  done
fi

# tracker file
touch /etc/system-setup

# DOC-4.1
./change-hostname.sh "${NEWHOSTNAME}"

# DOC-4.2
./setup-network-interfaces.sh

# DOC-4.5
locale-gen en_US.UTF-8
#dpkg-reconfigure locales
OUTFILE="/etc/default/locale"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
cat >"${OUTFILE}" <<EOF
LANG="en_US.UTF-8"
EOF

#dpkg-reconfigure tzdata
ln -sf /usr/share/zoneinfo/America/Toronto /etc/localtime

ln -s /proc/self/mounts /etc/mtab

# DOC-4.6
./apt-install.sh

# tracker file
rm /etc/system-setup

# DOC-8.3
./setup-nocompress-logrotate.sh

#service docker stop || true
#OUTFILE="/etc/default/docker"
#if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
#  cp -a "${OUTFILE}" "${OUTFILE}.original"
#fi
#cat >>"${OUTFILE}" <<EOF
#DOCKER_OPTS="--storage-driver=zfs"
#EOF
#service docker start || true

./setup-sshd_config.sh

# DOC-4.9
addgroup --system lpadmin
addgroup --system sambashare
addgroup --system docker

# DOC-4.11
zfs set mountpoint=legacy "${ZFS_ROOT_POOL}/var/log"
zfs set mountpoint=legacy "${ZFS_ROOT_POOL}/var/tmp"
cat >>/etc/fstab <<EOF
${ZFS_ROOT_POOL}/var/log /var/log zfs defaults 0 0
${ZFS_ROOT_POOL}/var/tmp /var/tmp zfs defaults 0 0
EOF

# DOC-5.1
#grub-probe /

# DOC-5.2
update-initramfs -c -k all

# DOC-5.3
OUTFILE="/etc/default/grub"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
sed -i 's;quiet splash;;' "${OUTFILE}"

# DOC-5.4
update-grub

# DOC-5.5
# Do this twice
for k in 1 2; do
  sleep 2
  # DOC-6.8
  for i in ${DISKS}; do
    grub-install "${i}"
  done
  # DOC-5.6
  ls /boot/grub/*/zfs.mod
done

OUTFILE="/etc/modprobe.d/zfs.conf"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
cat >>"${OUTFILE}" <<EOF
# Min 512MB / Max 1024 MB Limit
options zfs zfs_arc_min=536870912
options zfs zfs_arc_max=1073741824
EOF

install -m 755 ip.local /etc/ip.local
install -d -m 755 /usr/local
install -d -m 755 /usr/local/bin
ln -sf /etc/ip.local /usr/local/bin/ip.local

# Backup issue file
OUTFILE="/etc/issue"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
install -m 755 update-issue.local /etc/update-issue.local
ln -sf /etc/update-issue.local /etc/network/if-down.d/update-issue
ln -sf /etc/update-issue.local /etc/network/if-up.d/update-issue

install -m 700 firstboot.local /etc/firstboot.local
install -m 700 firstboot /etc/init.d/firstboot
ln -sf /etc/init.d/firstboot /etc/rc2.d/S99firstboot
ln -sf /etc/init.d/firstboot /etc/rc3.d/S99firstboot
ln -sf /etc/init.d/firstboot /etc/rc4.d/S99firstboot
ln -sf /etc/init.d/firstboot /etc/rc5.d/S99firstboot
touch /etc/firstboot

# DOC-6.1
zfs snapshot -r "${ZFS_ROOT_POOL}"@00-install

cat <<EOF
###################
#  End of script  #
###################
EOF
