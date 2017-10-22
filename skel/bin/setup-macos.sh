#!/usr/bin/env bash
set -e
set -x

eval $(_environment.sh)

# Xcode (for git)
xcode-select --install || true
xcode-select --install 2>&1 | grep "already installed"

# Homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Update curl
brew install curl
[ ! -e /usr/local/bin/curl ] && ln -s ../Cellar/curl/7.55.1/bin/curl /usr/local/bin/curl

# Install other tools
for i in \
  bash-completion \
  jq \
  wget \
  git \
  caskroom/cask/google-chrome \
  caskroom/cask/firefox \
  caskroom/cask/atom \
  caskroom/cask/vagrant \
  vagrant-completion \
  npm \
  ruby \
  go \
  shellcheck \
  shfmt \
  docker \
  docker-compose \
  caskroom/cask/virtualbox \
; do
  brew install $i || brew upgrade $i
done

# Update npm
npm install --global npm

# Linting tools via NPM
npm install --global \
  yaml-js \
  standard

# Temporary use Internet gem source
printf -- "---\n:backtrace: false\n:bulk_threshold: 1000\n:update_sources: true\n:verbose: true\ngem: --no-ri --no-rdoc\nbenchmark: false\n" > ~/.gemrc

# Linting tools via Gem
gem install \
  puppet-lint \
  bundler

# Setup use of Artifactory gem source
printf -- "---\n:backtrace: false\n:bulk_threshold: 1000\n:sources:\n- ${GEM_SOURCE}\n:update_sources: true\n:verbose: true\ngem: --no-ri --no-rdoc\nbenchmark: false\n" > ~/.gemrc
bundle config ${artifactory_host} ${artifactory_username}:${artifactory_password}
# bundle install

# Configure puppet module_repository
[ ! -d ~/.puppetlabs/etc/puppet ] && mkdir -p ~/.puppetlabs/etc/puppet
[ ! -f ~/.puppetlabs/etc/puppet/puppet.conf ] && touch ~/.puppetlabs/etc/puppet/puppet.conf
grep -q "module_repository" ~/.puppetlabs/etc/puppet/puppet.conf || tee -a ~/.puppetlabs/etc/puppet/puppet.conf <<EOF
[main]
module_repository=${BEAKER_FORGE_HOST}
EOF

# Atom Editor packages
apm install \
  linter \
  linter-ui-default \
  intentions \
  busy-signal \
  linter-shellcheck \
  format-shell \
  linter-ruby \
  linter-erb \
  linter-python \
  linter-js-yaml \
  linter-js-standard \
  language-puppet \
  linter-puppet-lint \
  atom-alignment

# Docker-Machine
docker-machine inspect default >/dev/null 2>&1 || docker-machine create -d virtualbox default

# Set environment variables for docker before using docker-cli
#eval $(docker-machine env default)

# Now you can list docker containers
#docker ps -a

# Set proxy for dockerd service so you can pull through proxy
#docker-machine ssh
#DOCKER_REGISTRY_HOST="reg.my.domain"
#DOCKER_REGISTRY_PORT="5001"
#DOCKER_REGISTRY="${DOCKER_REGISTRY_HOST}:${DOCKER_REGISTRY_PORT}"
#mkdir -p /etc/docker/certs.d/${DOCKER_REGISTRY}
#echo | openssl s_client -servername ${DOCKER_REGISTRY_HOST} -connect ${DOCKER_REGISTRY} 2>/dev/null | openssl x509 >> /etc/docker/certs.d/${DOCKER_REGISTRY}/ca.crt
#sudo tee /var/lib/boot2docker/profile <<EOF
cat <<EOF
EXTRA_ARGS='
--label provider=virtualbox

'
CACERT=/var/lib/boot2docker/ca.pem
DOCKER_HOST='-H tcp://0.0.0.0:2376'
DOCKER_STORAGE=aufs
DOCKER_TLS=auto
SERVERKEY=/var/lib/boot2docker/server-key.pem
SERVERCERT=/var/lib/boot2docker/server.pem
export HTTP_PROXY="${http_proxy}"
export HTTPS_PROXY="${http_proxy}"
export NO_PROXY="${no_proxy}"
EOF
# Restart dockerd for proxy to take effect
#sudo /etc/init.d/docker restart
