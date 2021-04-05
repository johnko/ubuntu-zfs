#!/usr/bin/env bash
set -exuo pipefail

ln -f -s Vagrantfile1_livecd.rb Vagrantfile
vagrant destroy --force || true

vmdk1="${HOME}/VirtualBox VMs/ubuntuzfs/ubuntu-focal-20.04-cloudimg-configdrive.vmdk"
[ -e "${vmdk1}" ] && rm "${vmdk1}"
vmdk2="${HOME}/VirtualBox VMs/ubuntuzfs/ubuntu-focal-20.04-cloudimg.vmdk"
[ -e "${vmdk2}" ] && rm "${vmdk2}"

ln -f -s Vagrantfile1_livecd.rb Vagrantfile
vagrant up

ln -f -s Vagrantfile2_rootonzfs.rb Vagrantfile
vagrant up --provision

ln -f -s Vagrantfile4_nas.rb Vagrantfile
vagrant up --provision
