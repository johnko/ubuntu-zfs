#!/usr/bin/env bash
set -e
set -x

NEWUSER="${1}"
NEWHOME="/home/${NEWUSER}"
NEWGROUPS=""
if [ $(find /home -mindepth 1 -maxdepth 1 | wc -l) -eq 0 ]; then
  # first user can be a super user
  NEWGROUPS="-G adm,cdrom,dip,lpadmin,plugdev,sambashare,docker,sudo"
  OUTFILE="/etc/sudoers.d/${NEWUSER}"
  if [ ! -f "${OUTFILE}" ]; then
    cat >"${OUTFILE}" <<EOF
## Uncomment the line below to allow sudo without password
## THIS IS NOT RECOMMENDED!
#
#${NEWUSER} ALL=(ALL) NOPASSWD: ALL
EOF
    chmod o-rwx "${OUTFILE}"
  fi
fi
NEWSKEL="/etc/skel"

# DOC-6.7
# password is admin
useradd -d "${NEWHOME}" ${NEWGROUPS} -m -k "${NEWSKEL}" -p '$6$ZukFU3LL$jGgdl2h6oSt/j06odeBaTPyWCwobck.GQA1DJVwEmYkji1DMDMj3WA66dCBpCer5hpavx8ArScr5lLvS4VXMg/' -s /bin/bash -U "${NEWUSER}"

#usermod -a ${NEWGROUPS} ${NEWUSER}

install -d -m 700 -o "${NEWUSER}" -g "${NEWUSER}" "${NEWHOME}/.vim"
install -d -m 700 -o "${NEWUSER}" -g "${NEWUSER}" "${NEWHOME}/.vim/backups"
install -d -m 700 -o "${NEWUSER}" -g "${NEWUSER}" "${NEWHOME}/.vim/swaps"
install -d -m 700 -o "${NEWUSER}" -g "${NEWUSER}" "${NEWHOME}/.vim/undo"

mv "${NEWHOME}" "${NEWHOME}.original"
zfs create "system${NEWHOME}"
chown -R "${NEWUSER}:${NEWUSER}" "${NEWHOME}"
find "${NEWHOME}.original" -maxdepth 1 -mindepth 1 -exec mv {} "${NEWHOME}" \;
rmdir "${NEWHOME}.original"

if [ -d /root/ubuntu-zfs/skel ]; then
  for i in /root/ubuntu-zfs/skel/.* /root/ubuntu-zfs/skel/*; do
    case ${i##*/} in
    . | ..)
      echo "Skipping ${i##*/}"
      ;;
    *)
      OUTFILE="${NEWHOME}/${i##*/}"
      if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
        cp -a "${OUTFILE}" "${OUTFILE}.original"
      fi
      [ -f "${i}" ] && install -m 600 -o "${NEWUSER}" -g "${NEWUSER}" "${i}" "${OUTFILE}"
      if [ -d "${i}" ]; then
        cp -a "${i}" "${NEWHOME}"
        chown -R "${NEWUSER}:${NEWUSER}" "${OUTFILE}"
        # remove group and other permissions
        find "${OUTFILE}" -exec chmod go-rwx {} \;
      fi
      ;;
    esac
  done
fi

if [ -e /root/.apt-cache ]; then
  mv /root/.apt-cache "${NEWHOME}/.apt-cache"
  chown -R "${NEWUSER}:${NEWUSER}" "${NEWHOME}/.apt-cache"
fi
