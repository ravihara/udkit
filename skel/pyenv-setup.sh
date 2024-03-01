#!/bin/bash

LATEST_PYVER=${1:-3.11.8}

## Install system dependencies
sudo apt update -y && sudo apt dist-upgrade -y
sudo apt install -y fontconfig curl rsync wget htop jq tree git bzip2 zip unzip net-tools vim universal-ctags \
  gpg xfonts-utils apt-transport-https locales tzdata libcap2-bin procps iproute2 nano xz-utils build-essential \
  make automake autoconf libtool intltool cmake pkg-config swig libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libncursesw5-dev tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libgdbm-dev libnss3-dev \
  uuid-dev && sync

## Cleanup apt packages
sudo apt autoremove --purge -y && sudo apt clean && sudo dpkg --configure -a

## Install pyenv
if [ -z "$(which pyenv 2>/dev/null)" ]; then
  curl https://pyenv.run | bash

  export PATH="${HOME}/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
else
  echo -e "pyenv is already installed, trying to update it..."
  pyenv update && sync
fi

## Install latest python3
if [ -z "$(pyenv versions | grep -v grep | grep "${LATEST_PYVER}")" ]; then
  pyenv install ${LATEST_PYVER} && sync
else
  echo -e "python-${LATEST_PYVER} is already installed, skipping it."
fi

## Set global python version
pyenv rehash
pyenv global ${LATEST_PYVER} && sync
python3 -m pip install -U --upgrade wheel setuptools pybind11 pip

## Install poetry
if [ -z "$(which poetry 2>/dev/null)" ]; then
  curl -sSL https://install.python-poetry.org | python3 -
else
  echo -e "python-poetry already installed, trying to update it..."
  poetry self update
fi

echo "All Done."
