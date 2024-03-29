#!/usr/bin/env bash
set -e
set -x

KERN_TARGET=${1}
if [ -z "${KERN_TARGET}" ]; then
  KERN_TARGET=$(uname -r)
fi

if lsusb | grep -q -i "ID 2357:010d"; then

  # rtl8812au-dkms is in universe
  which apt-add-repository || apt-get install --yes software-properties-common
  apt-add-repository universe
  if [ -z "${RSYNC_CACHE_SERVER}" ]; then
    apt-get update
  fi

  # need a compiler and linux headers
  apt-get install --yes build-essential linux-headers-generic
  # current kernel may be different
  # example livecd has linux-headers-4.15.0-29-generic but debootstrap installs linux-headers-4.15.0-33-generic
  KERN_CUR="$(uname -r)"
  apt-get install --yes linux-headers-${KERN_CUR} linux-headers-${KERN_TARGET}

  # rtl8812au-dkms is driver for TP-Link - Archer T4U AC1300, https://github.com/diederikdehaas/rtl8812AU/pull/105/files
  # only install after linux headers are available
  apt-get install --yes rtl8812au-dkms

  # get driver source folder
  RTL_SRC=$(dpkg -L rtl8812au-dkms | grep -o '^/[^/]*/[^/]*/[^/]*' | uniq -c | sort -nr | head -n 1 | awk '{print $2}')

  # get dynamic module and version
  # example KMOD_NAME="rtl8812au" and KMOD_VER="4.3.8.12175.20140902+dfsg"
  KMOD_NAME=$(echo $RTL_SRC | awk -F/ '{print $NF}' | awk -F- '{print $1}')
  KMOD_VER=$(echo $RTL_SRC | awk -F/ '{print $NF}' | awk -F- '{print $NF}')

  # patch the usb_intf.c file to add the Archer T4U ID
  PATCH_FILE="${RTL_SRC}/os_dep/linux/usb_intf.c.patch"
  base64 -d >"${PATCH_FILE}" <<EOF
KioqIHVzYl9pbnRmLmMub3JpZwkyMDE4LTA4LTI3IDIyOjM3OjA3LjYwNDk2NDgzNiAtMDQwMAot
LS0gdXNiX2ludGYuYwkyMDE4LTA4LTI3IDIyOjQ3OjAyLjEyODAzMTk1MSAtMDQwMAoqKioqKioq
KioqKioqKioKKioqIDMwNCwzMDUgKioqKgotLS0gMzA0LDMwNiAtLS0tCiAgCXtVU0JfREVWSUNF
KDB4MjM1NywgMHgwMTAxKSwuZHJpdmVyX2luZm8gPSBSVEw4ODEyfSwgLyogVFAtTGluayAtIEFy
Y2hlciBUNFUgKi8KKyAJe1VTQl9ERVZJQ0UoMHgyMzU3LCAweDAxMGQpLC5kcml2ZXJfaW5mbyA9
IFJUTDg4MTJ9LCAvKiBUUC1MaW5rIC0gQXJjaGVyIFQ0VSAqLwogIAl7VVNCX0RFVklDRSgweDIz
NTcsIDB4MDEwMyksLmRyaXZlcl9pbmZvID0gUlRMODgxMn0sIC8qIFRQLUxpbmsgLSBBcmNoZXIg
VDRVSCAqLwo=
EOF
  patch -N ${RTL_SRC}/os_dep/linux/usb_intf.c "${PATCH_FILE}" || true

  # this may or may not have already been added during install of rtl8812au-dkms
  MP_NAME="8812au"
  # remove the module if exist
  if [ "${KERN_CUR}" == "${KERN_TARGET}" ]; then
    if lsmod | grep -q "${MP_NAME}"; then
      modprobe -r ${MP_NAME} || true
      rmmod ${MP_NAME} || true
    fi
  fi
  # uninstall and remove the module for livecd kernel and new kernel
  dkms uninstall -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_TARGET} || true
  dkms remove -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_TARGET} || true
  # check kernel module is absent (strings are both empty)
  if [ "${KERN_CUR}" == "${KERN_TARGET}" ]; then
    test "x" == x$(lsmod | grep "${MP_NAME}")
  fi

  # manual build
  # libelf-dev needed to compile driver
  #apt-get install --yes libelf-dev
  #cd ${RTL_SRC} && make clean && make && make install

  # add, build and install the module source for livecd kernel and new kernel
  dkms add -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_TARGET} || true
  dkms build -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_TARGET}
  dkms install -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_TARGET}
  # load module into kernel if not exist, then check that kernel module is present
  if [ "${KERN_CUR}" == "${KERN_TARGET}" ]; then
    lsmod | grep -q "${MP_NAME}" || modprobe ${MP_NAME}
    lsmod | grep "${MP_NAME}"
  fi

  # check that a network interface exists
  #ip link | grep "wlx"
fi
