#!/usr/bin/env bash
set -e
set -x

NEWUSER="${LOGNAME}"

OUTFILE="/etc/sudoers.d/${NEWUSER}"
sudo tee "${OUTFILE}" <<EOF
# Uncomment the line below to allow sudo without password
# THIS IS NOT RECOMMENDED!

${NEWUSER} ALL=(ALL) NOPASSWD: ALL
EOF
