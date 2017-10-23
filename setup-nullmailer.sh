#!/usr/bin/env bash
set -e
set -x

cd /root/ubuntu-zfs

. ./env.sh

OUTFILE="/etc/nullmailer/remotes"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
if [ -n "${GMAIL_USER}" ] && [ -n "${GMAIL_PASSWORD}" ]; then
  cat >"${OUTFILE}" <<EOF
smtp.gmail.com smtp --port=587 --starttls --user=${GMAIL_USER} --pass=${GMAIL_PASSWORD}
EOF
fi
chmod 600 "${OUTFILE}"

OUTFILE="/etc/nullmailer/adminaddr"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
if [ -n "${GMAIL_USER}" ]; then
  cat >"${OUTFILE}" <<EOF
${GMAIL_USER}
EOF
fi
chmod 644 "${OUTFILE}"
