#!/bin/bash -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
UDKIT_BASE=$(cd -- "$(dirname -- "${SCRIPT_DIR}")" &>/dev/null && pwd)

PY_VERSION=${1:-3.11.11}
GPG_KEY=A035C8C19219BA821ECEA86B64E628F8D684696D

if [[ -n "$2" ]] && [[ "$2" == "true" ]]; then
  IS_DEFAULT_PY=true
else
  IS_DEFAULT_PY=false
fi

source ~/.udkit/funcs.bash

if [[ -d "${UDKIT_BASE}/dist/py-${PY_VERSION}" ]]; then
  echo_error "Python ${PY_VERSION} is already installed."
  exit 1
fi

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
  echo_info "Installing dependencies for APT-based systems"
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y \
    apt-transport-https \
    build-essential \
    bind9-dnsutils \
    ca-certificates \
    curl \
    g++ \
    git \
    gnupg \
    htop \
    iproute2 \
    jq \
    libcap2-bin \
    libsm6 \
    llvm \
    locales \
    make \
    netbase \
    procps \
    swig \
    telnet \
    tree \
    tzdata \
    wget \
    xz-utils \
    libncurses5-dev \
    libkrb5-dev \
    dpkg-dev \
    libbluetooth-dev \
    libbz2-dev \
    libc6-dev \
    libdb-dev \
    libffi-dev \
    libgdbm-dev \
    liblzma-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    tk-dev \
    uuid-dev \
    zlib1g-dev
  sync && sudo apt autoremove --purge -y && sudo apt clean && sudo dpkg --configure -a
elif [[ "$OS" == "fedora" || "$OS" == "rhel" || "$OS" == "centos" || "$OS" == "rocky" || "$OS" == "almalinux" ]]; then
  echo_info "Installing dependencies for DNF-based systems"
  sudo dnf install -y git pkg-config dnf-plugins-core
  sudo dnf builddep -y python3
  sudo dnf install -y \
    gcc gcc-c++ gdb lzma glibc-devel libstdc++-devel openssl-devel \
    readline-devel zlib-devel libffi-devel bzip2-devel xz-devel \
    sqlite sqlite-devel sqlite-libs libuuid-devel gdbm-libs perf \
    expat expat-devel mpdecimal python3-pip
else
  echo_error "Unsupported OS: $OS"
  exit 1
fi

wget -O python.tar.xz "https://www.python.org/ftp/python/${PY_VERSION%%[a-z]*}/Python-$PY_VERSION.tar.xz"
wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PY_VERSION%%[a-z]*}/Python-$PY_VERSION.tar.xz.asc"

GNUPGHOME="$(mktemp -d --suffix=gpg)"
export GNUPGHOME

gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY"
gpg --batch --verify python.tar.xz.asc python.tar.xz
gpgconf --kill all
rm -rf "$GNUPGHOME" python.tar.xz.asc

TMP_SRC_DIR="$(mktemp -d --suffix=python)"
tar --extract --directory "$TMP_SRC_DIR" --strip-components=1 --file python.tar.xz
rm python.tar.xz

pushd "$TMP_SRC_DIR" >/dev/null
./configure \
  --enable-loadable-sqlite-extensions \
  --enable-optimizations \
  --enable-option-checking=fatal \
  --enable-shared \
  --with-lto \
  --with-ensurepip \
  --prefix=${UDKIT_BASE}/dist/py-${PY_VERSION}

make -j"$(nproc)" && make install && sync
popd >/dev/null

## Setup symlinks and update basic python tools
pushd ${UDKIT_BASE}/dist >/dev/null

pushd py-${PY_VERSION}/bin >/dev/null
for src in idle3 pip3 pydoc3 python3 python3-config; do
  dst="$(echo "${src}" | tr -d 3)"
  [ -s "${src}" ]
  [ ! -e "${dst}" ]
  ln -svT "${src}" "${dst}"
done

echo "Refreshing python tools..."
./python -m pip install -U --upgrade wheel setuptools pybind11 pip
popd >/dev/null

if [[ "$IS_DEFAULT_PY" == "true" ]]; then
  echo "Setting default python version to ${PY_VERSION}"
  rm -f py-udk
  ln -s py-${PY_VERSION} py-udk
fi

popd >/dev/null

rm -rf "$TMP_SRC_DIR"
echo "All Done."
