#!/usr/bin/env bash
set -e
set -x

eval $(_environment.sh)

puppetbundlecheck.sh



[ ! -d /opt/puppetlabs/puppet/ssl ] && sudo mkdir -p /opt/puppetlabs/puppet/ssl
[ ! -f /opt/puppetlabs/puppet/ssl/cert.pem ] && sudo touch /opt/puppetlabs/puppet/ssl/cert.pem

if [ -e ~/Desktop/code/puppet-dev-env/macos/usr/local/lib/ruby/gems/2.4.0/gems/beaker-vagrant-0.1.0/lib/beaker/hypervisor/vagrant.rb ] \
  && [ -e ./vendor/bundle/ruby/2.4.0/gems/beaker-vagrant-0.1.0/lib/beaker/hypervisor/vagrant.rb ]; then
    diff ~/Desktop/code/puppet-dev-env/macos/usr/local/lib/ruby/gems/2.4.0/gems/beaker-vagrant-0.1.0/lib/beaker/hypervisor/vagrant.rb ./vendor/bundle/ruby/2.4.0/gems/beaker-vagrant-0.1.0/lib/beaker/hypervisor/vagrant.rb \
      || cp ~/Desktop/code/puppet-dev-env/macos/usr/local/lib/ruby/gems/2.4.0/gems/beaker-vagrant-0.1.0/lib/beaker/hypervisor/vagrant.rb ./vendor/bundle/ruby/2.4.0/gems/beaker-vagrant-0.1.0/lib/beaker/hypervisor/vagrant.rb
fi

bundle exec rake beaker:el-7-x64-vagrant
