#!/bin/bash

LATEST_PYVER=3.10.10

## Install core dependencies
sudo apt update -y && apt upgrade -y
sudo apt install -y build-essential g++ make automake autoconf libtool intltool colormake cmake \
    curl rsync wget htop jq tree git bzip2 zip unzip net-tools vim universal-ctags gpg apt-transport-https

## Install python dependencies
sudo apt -y install zlib1g-dev build-essential libgdbm-dev libncurses5-dev libssl-dev libnss3-dev \
    libffi-dev libreadline-dev wget libsqlite3-dev libbz2-dev uuid-dev liblzma-dev

## Cleanup apt packages
sudo apt autoremove --purge -y && sudo apt clean && sudo dpkg --configure -a

## Install pyenv
curl https://pyenv.run | bash

## Pyenv configuration
if [ -z "$(which pyenv 2>/dev/null)" ]; then
    export PATH="$HOME/.pyenv/bin:$PATH"

    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

## Install latest python3
pyenv install $LATEST_PYVER && sync && pyenv global $LATEST_PYVER
sync && cd $(pwd)

## Install poetry
curl -sSL https://install.python-poetry.org | python3 -
