#!/usr/bin/env bash
set -e
set -x

all_gems() {
  gem list | \
    awk '{print $1}' | \
    egrep -v '^(bundler|puppet-lint)$' | \
    egrep -v '^(xmlrpc|test-unit|rdoc|rake|psych|power_assert|openssl|net-telnet|minitest|json|io-console|did_you_mean|bigdecimal)$'
}

all_gems | grep -i '[a-z]' && \
  gem uninstall -a -I -x $(all_gems)
