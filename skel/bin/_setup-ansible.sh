#!/usr/bin/env bash
set -e
set -x

which python2.7 || sudo apt-get install --yes python2.7

which pip || sudo apt-get install --yes python-pip
sudo pip install --upgrade pip

# dependency for ansible
sudo apt-get install --yes libssl-dev

sudo pip install ansible
