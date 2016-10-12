#!/usr/bin/env bash
set -e
set -x

which python || sudo apt-get install --yes python

sudo easy_install pip

sudo pip install ansible
