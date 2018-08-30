#!/usr/bin/env bash
set -e
set -x

eval $(_environment.sh)

puppetbundlecheck.sh

eval $(docker-machine env default)

[ ! -d /opt/puppetlabs/puppet/ssl ] && sudo mkdir -p /opt/puppetlabs/puppet/ssl
[ ! -f /opt/puppetlabs/puppet/ssl/cert.pem ] && sudo touch /opt/puppetlabs/puppet/ssl/cert.pem

bundle exec rake beaker:el-7-x64-docker
