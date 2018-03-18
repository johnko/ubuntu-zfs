#!/usr/bin/env bash
set -e
set -x

eval $(_environment.sh)

bundle install --jobs 4 --retry 3 --verbose --path vendor/bundle
bundle exec rake metadata_lint
bundle exec rake elcapitan
bundle exec rake lint

[ ! -d ~/.puppetlabs/etc/puppet ] && mkdir -p ~/.puppetlabs/etc/puppet
[ ! -f ~/.puppetlabs/etc/puppet/puppet.conf ] && touch ~/.puppetlabs/etc/puppet/puppet.conf
grep -q "module_repository" ~/.puppetlabs/etc/puppet/puppet.conf || tee -a ~/.puppetlabs/etc/puppet/puppet.conf <<EOF
[main]
module_repository=${BEAKER_FORGE_HOST}
EOF

bundle exec rake release_checks
