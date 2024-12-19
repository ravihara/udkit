#!/bin/bash -e

REQ_PYVER=${1:-3.11.11}

source ~/.udkit/funcs.bash

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  echo_error "Do not run this script as root or with sudo."
  exit 1
fi

# Detect the OS type
OS="$(. /etc/os-release && echo "$ID")"
echo_info "Detected OS: $OS"

# Install dependencies
if [[ "$OS" == "debian" || "$OS" == "ubuntu" ]]; then
  echo_info "Installing dependencies for Debian-based systems"
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    curl \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
    git
  sync && sudo apt autoremove --purge -y && sudo apt clean && sudo dpkg --configure -a
elif [[ "$OS" == "rhel" || "$OS" == "centos" || "$OS" == "rocky" || "$OS" == "almalinux" ]]; then
  echo_info "Installing dependencies for RHEL-based systems"
  sudo yum groupinstall -y "Development Tools"
  sudo yum install -y \
    gcc \
    zlib-devel \
    bzip2 \
    bzip2-devel \
    readline-devel \
    sqlite \
    sqlite-devel \
    openssl-devel \
    tk-devel \
    libffi-devel \
    xz-devel \
    git \
    curl
else
  echo_error "Unsupported OS: $OS"
  exit 1
fi

## Install pyenv
if [ -z "$(command -v pyenv 2>/dev/null)" ]; then
  curl https://pyenv.run | bash

  export PATH="${HOME}/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
else
  echo -e "pyenv is already installed, trying to update it..."
  pyenv update && sync
fi

## Install latest python3
if [ -z "$(pyenv versions | grep -v grep | grep "${REQ_PYVER}")" ]; then
  pyenv install ${REQ_PYVER} && sync
else
  echo -e "python-${REQ_PYVER} is already installed, skipping it."
fi

## Set global python version
pyenv rehash
pyenv global ${REQ_PYVER} && sync
python3 -m pip install -U --upgrade wheel setuptools pybind11 pip

## Install poetry
if [ -z "$(command -v poetry 2>/dev/null)" ]; then
  curl -sSL https://install.python-poetry.org | python3 -
else
  echo -e "python-poetry already installed, trying to update it..."
  poetry self update
fi

echo "All Done."
