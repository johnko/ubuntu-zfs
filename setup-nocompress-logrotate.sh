#!/usr/bin/env bash
set -e
set -x

for file in /etc/logrotate.d/* ; do
  if grep -Eq "(^|[^#y])compress" "${file}" ; then
    cp -a "${file}" "${file}.original"
    sed -i -r "s/(^|[^#y])(compress)/\1#\2/" "${file}"
  fi
done
