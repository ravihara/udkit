#!/bin/bash

LATEST_PYVER=${1:-3.10.10}

## Install core dependencies
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y build-essential g++ make automake autoconf libtool intltool colormake cmake pkg-config \
  fontconfig curl rsync wget htop jq tree git bzip2 zip unzip net-tools vim universal-ctags gpg xfonts-utils \
  apt-transport-https

## Install python dependencies
sudo apt -y install zlib1g-dev build-essential libgdbm-dev libncurses5-dev libssl-dev libnss3-dev \
  libffi-dev libreadline-dev wget libsqlite3-dev libbz2-dev uuid-dev liblzma-dev

## Cleanup apt packages
sudo apt autoremove --purge -y && sudo apt clean && sudo dpkg --configure -a

## Install pyenv
if [ -z "$(which pyenv 2>/dev/null)" ]; then
  curl https://pyenv.run | bash

  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
else
  echo -e "pyenv is already installed, skipping it."
fi

## Install latest python3
if [ -z "$(pyenv versions | grep -v grep | grep "$LATEST_PYVER")" ]; then
  pyenv install $LATEST_PYVER && sync
else
  echo -e "python-${LATEST_PYVER} is already installed, skipping it."
fi

## Set global python version
pyenv global $LATEST_PYVER && sync && cd $(pwd)

## Install poetry
if [ -n "$(which poetry 2>/dev/null)" ]; then
  curl -sSL https://install.python-poetry.org | python3 - --uninstall
fi

curl -sSL https://install.python-poetry.org | python3 -

echo "All Done."

