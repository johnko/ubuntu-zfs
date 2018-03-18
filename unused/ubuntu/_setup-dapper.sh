#!/usr/bin/env bash
set -e
set -x

which git || sudo apt-get install --yes git
which go || _setup-golang.sh

if [ ! -e /usr/bin/dapper ]; then
  go get github.com/rancher/dapper
  sudo mv ~/go/bin/dapper /usr/bin/dapper
fi
