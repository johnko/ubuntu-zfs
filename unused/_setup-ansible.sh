#!/usr/bin/env bash
set -e
set -x

export DEBIAN_FRONTEND=noninteractive

# Dependency for virtualenv
sudo apt-get install -y build-essential python-dev libffi-dev
which virtualenv || sudo apt-get install --yes python-virtualenv

# Dependency for ansible
sudo apt-get install -y libssl-dev

# Install ansible in a virtualenv
VENV_FOLDER="venv"
virtualenv ${VENV_FOLDER}
. ${VENV_FOLDER}/bin/activate
pip install --upgrade pip
pip install ansible

# Instructions to user
set +x
echo "Ansible setup complete!"
echo "Now you can:"
echo "    source ${VENV_FOLDER}/bin/activate"
echo "    ansible-playbook ..."
