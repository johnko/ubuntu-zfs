#!/usr/bin/env bash
set -e
set -x

sudo apt-get install --yes "linux-headers-$(uname -r)"
sudo apt-get install --yes virtualbox-5.0

sudo /sbin/rcvboxdrv setup
