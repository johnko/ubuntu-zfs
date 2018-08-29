#!/usr/bin/env bash
set -e
set -x

if lsusb | grep -q -i "ID 2357:010d"; then

  which apt-add-repository || apt-get install --yes software-properties-common
  apt-add-repository universe
  if [ -z "${RSYNC_CACHE_SERVER}" ]; then
    apt-get update
  fi
  
  # need a compiler and linux headers
  apt-get install --yes build-essential linux-headers-generic
  # current kernel may be different
  # example livecd has linux-headers-4.15.0-29-generic but debootstrap installs linux-headers-4.15.0-33-generic
  KERN_CUR="$( uname -r )"
  KERN_NEW=$( ls /usr/src/ | grep "linux-headers-.*generic" | tail -n 1 | sed 's;linux-headers-;;' )
  if [ "${KERN_CUR}" != "${KERN_NEW}" ]; then
    apt-get install --yes linux-headers-${KERN_NEW}
  fi

  # rtl8812au-dkms is driver for TP-Link - Archer T4U AC1300, https://github.com/diederikdehaas/rtl8812AU/pull/105/files
  apt-get install --yes rtl8812au-dkms

  # driver source folder
  RTL_SRC=$( dpkg -L rtl8812au-dkms | grep -o '^/[^/]*/[^/]*/[^/]*' | uniq -c | sort -nr | head -n 1 | awk '{print $2}' )

  # get dynamic module and version
  #KMOD_NAME="rtl8812au"
  KMOD_NAME=$( echo $RTL_SRC | awk -F/ '{print $NF}' | awk -F- '{print $1}' )
  #KMOD_VER="4.3.8.12175.20140902+dfsg"
  KMOD_VER=$( echo $RTL_SRC | awk -F/ '{print $NF}' | awk -F- '{print $NF}' )

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

  # this may have already been added during apt install
  MP_NAME="8812au"
  # remove the module if exist
  lsmod | grep -q "${MP_NAME}" || modprobe -r ${MP_NAME} || true
  # uninstall the module
    dkms uninstall -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_CUR} || true
  # remove the module source
    dkms remove    -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_CUR} || true
  if [ "${KERN_CUR}" != "${KERN_NEW}" ]; then
    dkms uninstall -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_NEW} || true
    dkms remove    -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_NEW} || true
  fi
  # check kernel module is absent (strings are both empty)
  test "x" == x$( lsmod | grep "${MP_NAME}" )

  # manual build
  # libelf-dev needed to compile driver
  #apt-get install --yes libelf-dev
  #cd ${RTL_SRC} && make clean && make && make install

  # add the module source
    dkms add     -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_CUR} || true
  # rebuild and reinstall the module
    dkms build   -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_CUR}
    dkms install -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_CUR}
  if [ "${KERN_CUR}" != "${KERN_NEW}" ]; then
    dkms add     -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_NEW} || true
    dkms build   -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_NEW}
    dkms install -m ${KMOD_NAME} -v ${KMOD_VER} -k ${KERN_NEW}
  fi
  # load module into kernel if not exist
  lsmod | grep -q "${MP_NAME}" || modprobe ${MP_NAME}
  # check that kernel module is present
  lsmod | grep "${MP_NAME}"

  # check if link exists
  ip link | grep "wlx"
fi
