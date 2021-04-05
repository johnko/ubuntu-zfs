#!/usr/bin/env bash
set -e
set -x

if [ -z "${1}" ]; then
  echo "USAGE: $0 NEWHOSTNAME" >&2
  exit 1
fi

if [ ! -f /etc/system-setup ]; then
  hostname "${1}"
fi

OUTFILE="/etc/hostname"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
cat >"${OUTFILE}" <<EOF
${1}
EOF

OUTFILE="/etc/hosts"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
sed -i "s;127.0.1.1.*;127.0.1.1 ${1};" "${OUTFILE}"
if ! grep -q "^[^#]*127.0.1.1" "${OUTFILE}"; then
  cat >>"${OUTFILE}" <<EOF
127.0.1.1 ${1}
EOF
fi
