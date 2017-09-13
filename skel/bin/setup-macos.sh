#!/usr/bin/env bash
set -e
set -x

# Proxy for your current Terminal session
#export http_proxy="http://gateway:8000"
#export https_proxy="${http_proxy}"
# No proxy for IP of the docker-machine
#export no_proxy="192.168.99.100,more.domains"

# Xcode (for git)
xcode-select --install || true
xcode-select --install 2>&1 | grep "already installed"

# Homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install curl
[ ! -e /usr/local/bin/curl ] && ln -s ../Cellar/curl/7.55.1/bin/curl /usr/local/bin/curl

for i in \
  bash-completion \
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

# Linting tools via NPM
npm install --global npm

npm install --global \
  yaml-js \
  standard

# Linting tools via Gem
gem install \
  puppet-lint

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
  linter-puppet-lint

# Docker-Machine
docker-machine inspect default >/dev/null 2>&1 || docker-machine create -d virtualbox default

# Set environment variables for docker
#eval $(docker-machine env default)

# Now you can list docker containers
#docker ps -a

# Set proxy for dockerd service so you can pull through proxy
#docker-machine ssh
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
