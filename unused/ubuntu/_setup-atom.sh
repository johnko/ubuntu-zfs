#!/usr/bin/env bash
set -e
set -x

#exit if no desktop installed
dpkg -l | grep ubuntu-desktop || exit 0

if ! which atom; then
  FILE=atom.deb
  mkdir -p "${HOME}/.apt-cache"
  [ ! -e "${HOME}/.apt-cache/${FILE}" ] && curl -o "${HOME}/.apt-cache/${FILE}" -L https://atom.io/download/deb
  sudo dpkg -i "${HOME}/.apt-cache/${FILE}"
fi

which shellcheck || sudo apt-get install --yes shellcheck
which git || sudo apt-get install --yes git
which go || _setup-golang.sh

apm install linter
apm install linter-ui-default
apm install intentions
apm install busy-signal

apm install linter-shellcheck
go get -u github.com/mvdan/sh/cmd/shfmt
apm install format-shell
