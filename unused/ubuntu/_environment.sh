#!/usr/bin/env bash
set -e
#set -x

# Set your Artifactory authentication token
artifactory_username="user"
artifactory_password="password"
artifactory_host="more.domain"
vagrant_box_host="vagrant.box"
docker_machine="192.168.99.100"
proxy_gateway="gateway"
proxy_port="8000"

http_proxy="http://${proxy_gateway}:${proxy_port}"
https_proxy="${http_proxy}"
no_proxy="${docker_machine},${artifactory_host},${vagrant_box_host}"
USER=${artifactory_username}
PASSWORD=${artifactory_password}
BEAKER_debug=true
BEAKER_AF_USER=${artifactory_username}
BEAKER_AF_PASSWORD=${artifactory_password}
BEAKER_PACKAGE_PROXY=${http_proxy}
BEAKER_YUM_BASEURL="http://${artifactory_username}:${artifactory_password}@${artifactory_host}/artifactory/ext-yum/\$basearch"
BEAKER_FORGE_HOST="http://${artifactory_username}:${artifactory_password}@${artifactory_host}/artifactory/api/puppet/virtual-puppet"
GEM_SOURCE="http://${artifactory_username}:${artifactory_password}@${artifactory_host}/artifactory/api/gems/virtual-ruby/"
BEAKER_SSL_CERT_FILE="/opt/puppetlabs/puppet/ssl/cert.pem"

# Show these variables in output to be evaluated by other scripts
set | grep -E '^(http_|https_|no_|USER$|PASSWORD$|artifactory_|BEAKER_|GEM_)' | awk '{print "export "$0}'
