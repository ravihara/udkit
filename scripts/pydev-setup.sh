#!/bin/bash -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
UDKIT_BASE=$(cd -- "$(dirname -- "${SCRIPT_DIR}")" &>/dev/null && pwd)

PY_VERSION=${1:-3.11.11}
GPG_KEY=A035C8C19219BA821ECEA86B64E628F8D684696D
PY_SHA256=07a4356e912900e61a15cb0949a06c4a05012e213ecd6b4e84d0f67aabbee372

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
  echo_info "Installing dependencies for Debian-based systems"
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
    libmysqlclient-dev \
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
    mysql-devel \
    openssl-devel \
    tk-devel \
    libffi-devel \
    xz-devel \
    krb5-devel \
    git \
    curl
else
  echo_error "Unsupported OS: $OS"
  exit 1
fi

wget -O python.tar.xz "https://www.python.org/ftp/python/${PY_VERSION%%[a-z]*}/Python-$PY_VERSION.tar.xz"
echo "$PY_SHA256 *python.tar.xz" | sha256sum -c -
wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PY_VERSION%%[a-z]*}/Python-$PY_VERSION.tar.xz.asc"

GNUPGHOME="$(mktemp -d --suffix=gpg)"
export GNUPGHOME

gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY"
gpg --batch --verify python.tar.xz.asc python.tar.xz
gpgconf --kill all
rm -rf "$GNUPGHOME" python.tar.xz.asc

TMP_SRC_DIR="$(mktemp -d --suffix=python)"
mkdir -p "$TMP_SRC_DIR"
tar --extract --directory "$TMP_SRC_DIR" --strip-components=1 --file python.tar.xz
rm python.tar.xz

pushd "$TMP_SRC_DIR" >/dev/null
gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"
./configure \
  --build="$gnuArch" \
  --enable-loadable-sqlite-extensions \
  --enable-optimizations \
  --enable-option-checking=fatal \
  --enable-shared \
  --with-lto \
  --with-ensurepip \
  --prefix=${UDKIT_BASE}/dist/py-${PY_VERSION} \
  ;

nproc="$(nproc)"
EXTRA_CFLAGS="$(dpkg-buildflags --get CFLAGS)"
LDFLAGS="$(dpkg-buildflags --get LDFLAGS)"
LDFLAGS="${LDFLAGS:--Wl},--strip-all"
make -j "$nproc" \
  "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
  "LDFLAGS=${LDFLAGS:-}" \
  ;
# https://github.com/docker-library/python/issues/784
# prevent accidental usage of a system installed libpython of the same version
sync && rm python
make -j "$nproc" \
  "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
  "LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'"
sync && make install && sync
popd >/dev/null

## Setup symlinks and update basic python tools
pushd ${UDKIT_BASE}/dist >/dev/null

pushd py-${PY_VERSION}/bin >/dev/null
ln -s python3 python
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
