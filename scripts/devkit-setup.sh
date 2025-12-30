#!/bin/bash
set -eu

## Get the current script dir
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source ${SCRIPT_DIR}/funcs.bash

## Check for devkit setup tools
check_devkit_tools

## Check for atleast two arguments
if [[ $# -lt 2 ]]; then
    echo_error "Usage: $(basename $0) --kit=<devkit> --version=<version> [--force=true|false]"
    exit 1
fi

CACHE_DIR="${HOME}/.udkit/cache"
UDK_DIST="${HOME}/.udkit/dist"

mkdir -p $CACHE_DIR $UDK_DIST

_valid_cached_file() {
    filename=$1

    ## Check if the file is already cached and is not older than 30 days
    if [ -f "${CACHE_DIR}/${filename}" ]; then
        local last_modified=$(stat -c %Y "${CACHE_DIR}/${filename}")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_modified))
        local days_diff=$((time_diff / 86400))

        if [ $days_diff -lt 15 ]; then
            echo_info "Found already cached file $filename."
            return 0
        else
            echo_info "Cached file $filename is older than 15 days. Downloading again..."
            rm -f "${CACHE_DIR}/${filename}"
        fi
    fi

    return 1
}

_setup_pydev_packages() {
    sudo apt-get update
    sudo apt-get upgrade -y

    sudo apt-get install -y \
        apt-transport-https \
        dpkg-dev \
        gcc \
        git \
        libbluetooth-dev \
        libbz2-dev \
        libc6-dev \
        libdb-dev \
        libffi-dev \
        libgdbm-dev \
        libkrb5-dev \
        liblzma-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        make \
        tk-dev \
        uuid-dev \
        zlib1g-dev && sync

    sudo apt-get clean -y
    sudo apt-get autoremove --purge -y
    sudo dpkg --configure -a
    sudo rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
}

_install_python() {
    local pkgfile=$1
    local version=$2

    local pkg_bname=$(basename $pkgfile)
    local pkg_base=$(tar_xz_pkgbase $pkgfile)
    local python_dir="${UDK_DIST}/py-${version}"

    local python_bin="${python_dir}/bin"
    local python_lib="${python_dir}/lib"
    local python_inc="${python_dir}/include"

    echo_info "Installing Python ${version}..."
    _setup_pydev_packages

    tmpdir=$(mktemp -d --suffix=-src)
    GNUPGHOME="$(mktemp -d --suffix=-gnupg)"

    ## check if version starts with 3.11
    echo_info "Using GPG_KEY for ${version}..."

    if [[ "${version}" == 3.11* ]]; then
        GPG_KEY="A035C8C19219BA821ECEA86B64E628F8D684696D"
    elif [[ "${version}" == 3.12* ]]; then
        GPG_KEY="7169605F62C751356D054A26A821E680E5FA6305"
    else
        echo_error "Unsupported Python version for GPG verification: ${version}"
        return 1
    fi

    export GNUPGHOME

    ## Download python.targ.xz.asc into tmpdir
    curl -o "${tmpdir}/${pkg_bname}.asc" -L "https://www.python.org/ftp/python/${version}/${pkg_bname}.asc" || {
        echo_error "Failed to download python GPG signature."
        return 1
    }

    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "${GPG_KEY}"
    gpg --batch --verify "${tmpdir}/${pkg_bname}.asc" "${pkgfile}"
    { command -v gpgconf >/dev/null && gpgconf --kill all || :; }

    mkdir -p ${tmpdir}/python
    tar --extract --directory ${tmpdir}/python --strip-components=1 --file ${pkgfile} && sync
    cd ${tmpdir}/python

    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"
    ./configure \
        --build="$gnuArch" \
        --enable-loadable-sqlite-extensions \
        --enable-optimizations \
        --enable-option-checking=fatal \
        --enable-shared \
        --with-lto \
        --with-ensurepip \
        --prefix=${python_dir}

    EXTRA_CFLAGS="$(dpkg-buildflags --get CFLAGS)"
    LDFLAGS="$(dpkg-buildflags --get LDFLAGS)"
    LDFLAGS="${LDFLAGS:--Wl},--strip-all"

    make -j "$(nproc)" \
        "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
        "LDFLAGS=${LDFLAGS:-}"

    sync && rm python
    make -j "$(nproc)" \
        "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
        "LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'" \
        python

    sync && make install && sync
    cd -

    rm -rf "${tmpdir}" "${GNUPGHOME}"
    unset GNUPGHOME

    find ${python_dir} -depth \
        \( \
        \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
        -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
        \) -exec rm -rf '{}' + \
        ;

    if [ -d "${python_bin}" ] && [ -d "${python_lib}" ] && [ -d "${python_inc}" ]; then
        export PATH="${python_bin}:${PATH}"
        export LD_LIBRARY_PATH="${python_lib}:${LD_LIBRARY_PATH}"
        export PKG_CONFIG_PATH="${python_lib}/pkgconfig:${PKG_CONFIG_PATH}"
        export PYTHONDONTWRITEBYTECODE=1

        python3 --version
        pip3 --version
        pip3 install \
            --disable-pip-version-check \
            --no-cache-dir \
            --no-compile \
            setuptools \
            wheel

        for src in idle3 pip3 pydoc3 python3 python3-config; do
            dst="$(echo "${src}" | tr -d 3)"
            [ -s "${python_bin}/${src}" ]
            [ ! -e "${python_bin}/${dst}" ]
            ln -svT "${src}" "${python_bin}/${dst}"
        done

        echo_info "Python ${version} is installed successfully."
    else
        echo_error "Failed to install Python ${version}."
        return 1
    fi
}

_install_openjdk() {
    local pkgfile=$1
    local version=$2

    local pkg_base=$(tar_gz_pkgbase $pkgfile)
    local jdk_dir="${UDK_DIST}/jdk-${version}"

    local jdk_bin="${jdk_dir}/bin"
    local jdk_lib="${jdk_dir}/lib"
    local jdk_inc="${jdk_dir}/include"

    echo_info "Installing Temurin JDK ${version}..."
    tar -xf "${pkgfile}" -C "${UDK_DIST}" && sync

    if [ "${UDK_DIST}/${pkg_base}" != "${jdk_dir}" ]; then
        mv "${UDK_DIST}/${pkg_base}" "${jdk_dir}"
    fi

    if [ -d "${jdk_bin}" ] && [ -d "${jdk_lib}" ] && [ -d "${jdk_inc}" ]; then
        echo_info "Temurin JDK ${version} is installed successfully."
    else
        echo_error "Failed to install Temurin JDK ${version}."
        return 1
    fi
}

_install_nodejs() {
    local pkgfile=$1
    local version=$2

    local pkg_base=$(tar_pkgbase $pkgfile)
    local node_dir="${UDK_DIST}/node-${version}"

    local node_bin="${node_dir}/bin"
    local node_lib="${node_dir}/lib"
    local node_inc="${node_dir}/include"

    echo_info "Installing Node.js ${version}..."
    tar -xf "${pkgfile}" -C "${UDK_DIST}" && sync

    if [ "${UDK_DIST}/${pkg_base}" != "${node_dir}" ]; then
        mv "${UDK_DIST}/${pkg_base}" "${node_dir}"
    fi

    if [ -d "${node_bin}" ] && [ -d "${node_lib}" ] && [ -d "${node_inc}" ]; then
        echo_info "Node.js ${version} is installed successfully."
    else
        echo_error "Failed to install Node.js ${version}."
        return 1
    fi
}

_install_golang() {
    local pkgfile=$1
    local version=$2

    local pkg_base=$(tar_gz_pkgbase $pkgfile)
    local go_dir="${UDK_DIST}/go-${version}"

    local go_bin="${go_dir}/bin"
    local go_lib="${go_dir}/lib"

    echo_info "Installing Go ${version}..."
    tar -zxf "${pkgfile}" -C "${UDK_DIST}" && sync

    if [ "${UDK_DIST}/${pkg_base}" != "${go_dir}" ]; then
        mv "${UDK_DIST}/${pkg_base}" "${go_dir}"
    fi

    if [ -d "${go_bin}" ] && [ -d "${go_lib}" ]; then
        mkdir -p ${UDK_DIST}/goext
        echo_info "Go ${version} is installed successfully."
    else
        echo_error "Failed to install Go ${version}."
        return 1
    fi
}

_install_gradle() {
    local pkgfile=$1
    local version=$2

    local pkg_base=$(zip_pkgbase $pkgfile)
    local gradle_dir="${UDK_DIST}/gradle-${version}"

    local gradle_bin="${gradle_dir}/bin"
    local gradle_lib="${gradle_dir}/lib"

    echo_info "Installing Gradle ${version}..."
    unzip -qq "${pkgfile}" -d "${UDK_DIST}" && sync

    if [ "${UDK_DIST}/${pkg_base}" != "${gradle_dir}" ]; then
        mv "${UDK_DIST}/${pkg_base}" "${gradle_dir}"
    fi

    if [ -d "${gradle_bin}" ] && [ -d "${gradle_lib}" ]; then
        echo_info "Gradle ${version} is installed successfully."
    else
        echo_error "Failed to install Gradle ${version}."
        return 1
    fi
}

_install_maven() {
    local pkgfile=$1
    local version=$2

    local pkg_base=$(zip_pkgbase $pkgfile)
    local maven_dir="${UDK_DIST}/mvn-${version}"

    local maven_bin="${maven_dir}/bin"
    local maven_lib="${maven_dir}/lib"

    echo_info "Installing Maven ${version}..."
    unzip -qq "${pkgfile}" -d "${UDK_DIST}" && sync

    if [ "${UDK_DIST}/${pkg_base}" != "${maven_dir}" ]; then
        mv "${UDK_DIST}/${pkg_base}" "${maven_dir}"
    fi

    if [ -d "${maven_bin}" ] && [ -d "${maven_lib}" ]; then
        echo_info "Maven ${version} is installed successfully."
    else
        echo_error "Failed to install Maven ${version}."
        return 1
    fi
}

# Function to setup Python for build
setup_python() {
    local version=$1
    local force=$2
    local arch=""
    local python_dir="${UDK_DIST}/py-${version}"

    if [[ -z $version ]]; then
        echo_error "Usage: setup_python <version>"
        return 1
    fi

    if [ "$force" != "true" ]; then
        if [ -d "${python_dir}" ]; then
            echo_info "Python ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Python ${version}..."
        rm -rf "${python_dir}"
    fi

    case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    arm64 | aarch64) arch="aarch64" ;;
    *)
        echo_error "Unsupported architecture: $(uname -m)"
        return 1
        ;;
    esac

    # Construct the download URL
    local base_url="https://www.python.org/ftp/python"
    local filename="Python-${version}.tar.xz"
    local url="${base_url}/${version}/${filename}"

    # Check if the URL is valid
    if ! is_url_valid "${url}"; then
        echo_error "Invalid download URL: ${url}"
        return 1
    fi

    # Check for cached file or, download afresh
    if ! _valid_cached_file "${filename}"; then
        echo_info "Downloading Python version ${version} for linux-${arch}..."
        curl -o "${CACHE_DIR}/${filename}" -L "${url}" || {
            echo_error "Failed to download from ${url}"
            return 1
        }

        echo_info "Download completed. File: ${filename}"
    else
        echo_info "Using cached Python version ${version} package for linux-${arch}..."
    fi

    filename="${CACHE_DIR}/${filename}"

    # Install the Python tarball
    _install_python "${filename}" "${version}"
}

# Function to download Temurin JDK
setup_openjdk() {
    local version=$1
    local force=$2
    local arch=""
    local jdk_dir="${UDK_DIST}/jdk-${version}"

    if [[ -z $version ]]; then
        echo_error "Usage: setup_openjdk <version>"
        return 1
    fi

    if [ "$force" != "true" ]; then
        if [ -d "${jdk_dir}" ]; then
            echo_info "Temurin JDK ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Temurin JDK ${version}..."
        rm -rf "${jdk_dir}"
    fi

    case "$(uname -m)" in
    x86_64) arch="x64" ;;
    arm64 | aarch64) arch="aarch64" ;;
    *)
        echo_error "Unsupported architecture: $(uname -m)"
        return 1
        ;;
    esac

    # Construct the download URL
    local base_url="https://api.adoptium.net/v3/binary/latest"
    local package_type="jdk"
    local jvm_impl="hotspot"
    local url="${base_url}/${version}/ga/linux/${arch}/$package_type/${jvm_impl}/normal/adoptium"
    local filename="temurin-jdk-${version}-linux-${arch}.tar.gz"

    # Check if URL is valid
    if ! is_url_valid "${url}"; then
        echo_error "Invalid download URL: ${url}"
        return 1
    fi

    # Check for cached file or, download afresh
    if ! _valid_cached_file "${filename}"; then
        echo_info "Downloading Temurin JDK ${version} for linux-${arch}..."
        curl -o "${CACHE_DIR}/${filename}" -L "${url}" || {
            echo_error "Failed to download from ${url}"
            return 1
        }

        echo_info "Download completed. File: ${filename}"
    else
        echo_info "Using cached Temurin JDK ${version} package for linux-${arch}..."
    fi

    filename="${CACHE_DIR}/${filename}"

    # Install the OpenJDK tarball
    _install_openjdk "${filename}" "${version}"
}

# Function to download Node.js binary package
setup_nodejs() {
    local version=$1
    local force=$2
    local arch=""
    local node_dir="${UDK_DIST}/node-${version}"

    if [[ -z $version ]]; then
        echo_error "Usage: setup_nodejs <version>"
        return 1
    fi

    if [ "$force" != "true" ]; then
        if [ -d "${node_dir}" ]; then
            echo_info "Node.js ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Node.js ${version}..."
        rm -rf "${node_dir}"
    fi

    case "$(uname -m)" in
    x86_64) arch="x64" ;;
    arm64 | aarch64) arch="arm64" ;;
    *)
        echo_error "Unsupported architecture: $(uname -m)"
        return 1
        ;;
    esac

    # Construct the download URL
    local base_url="https://nodejs.org/dist"
    local filename="node-v${version}-linux-${arch}.tar.xz"
    local url="${base_url}/v${version}/${filename}"

    # Check if the URL is valid
    if ! is_url_valid "${url}"; then
        echo_error "Invalid download URL: ${url}"
        return 1
    fi

    # Check for cached file or, download afresh
    if ! _valid_cached_file "${filename}"; then
        echo_info "Downloading Node.js version ${version} for linux-${arch}..."
        curl -o "${CACHE_DIR}/${filename}" -L "${url}" || {
            echo_error "Failed to download from ${url}"
            return 1
        }

        echo_info "Download completed. File: ${filename}"
    else
        echo_info "Using cached Node.js version ${version} package for linux-${arch}..."
    fi

    filename="${CACHE_DIR}/${filename}"

    # Install the Node.js tarball
    _install_nodejs "${filename}" "${version}"
}

# Function to download Go
setup_golang() {
    local version=$1
    local force=$2
    local arch=""
    local go_dir="${UDK_DIST}/go-${version}"

    if [[ -z $version ]]; then
        echo_error "Usage: setup_golang <version>"
        return 1
    fi

    if [ "$force" != "true" ]; then
        if [ -d "${go_dir}" ]; then
            echo_info "Go ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Go ${version}..."
        rm -rf "${go_dir}"
    fi

    case "$(uname -m)" in
    x86_64) arch="amd64" ;;
    arm64 | aarch64) arch="arm64" ;;
    *)
        echo_error "Unsupported architecture: $(uname -m)"
        return 1
        ;;
    esac

    # Construct the download URL
    local base_url="https://go.dev/dl"
    local filename="go${version}.linux-${arch}.tar.gz"
    local url="${base_url}/${filename}"

    # Check if the URL is valid
    if ! is_url_valid "${url}"; then
        echo_error "Invalid download URL: ${url}"
        return 1
    fi

    # Check for cached file or, download afresh
    if ! _valid_cached_file "${filename}"; then
        echo_info "Downloading Go version ${version} for linux-${arch}..."
        curl -o "${CACHE_DIR}/${filename}" -L "${url}" || {
            echo_error "Failed to download from ${url}"
            return 1
        }

        echo_info "Download completed. File: ${filename}"
    else
        echo_info "Using cached Go version ${version} package for linux-${arch}..."
    fi

    filename="${CACHE_DIR}/${filename}"

    # Install the Go binary
    _install_golang "${filename}" "${version}"
}

# Function to download Gradle binary package
setup_gradle() {
    local version=$1
    local force=$2
    local gradle_dir="${UDK_DIST}/gradle-${version}"

    # Check if version is provided
    if [[ -z "$version" ]]; then
        echo_error "Error: Please provide the Gradle version as an argument."
        return 1
    fi

    if [ "$force" != "true" ]; then
        if [ -d "${gradle_dir}" ]; then
            echo_info "Gradle ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Gradle ${version}..."
        rm -rf "${gradle_dir}"
    fi

    local base_url="https://services.gradle.org/distributions"
    local filename="gradle-${version}-bin.zip"
    local url="${base_url}/${filename}"

    # Check if the URL is valid
    if ! is_url_valid "${url}"; then
        echo_error "Invalid download URL: ${url}"
        return 1
    fi

    # Check for cached file or, download afresh
    if ! _valid_cached_file "${filename}"; then
        echo_info "Downloading Gradle version $version from $url..."
        curl -o "${CACHE_DIR}/${filename}" -L "${url}" || {
            echo_error "Failed to download from ${url}"
            return 1
        }

        echo_info "Download completed. File: ${filename}"
    else
        echo_info "Using cached Gradle version $version package..."
    fi

    filename="${CACHE_DIR}/${filename}"

    # Install the Gradle binary package
    _install_gradle "${filename}" "${version}"
}

# Function to download Maven binary package
setup_maven() {
    local version=$1
    local force=$2
    local maven_dir="${UDK_DIST}/mvn-${version}"

    # Check if version is provided
    if [[ -z "$version" ]]; then
        echo_error "Error: Please provide the Maven version as an argument."
        return 1
    fi

    if [ "$force" != "true" ]; then
        if [ -d "${maven_dir}" ]; then
            echo_info "Maven ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Maven ${version}..."
        rm -rf "${maven_dir}"
    fi

    local base_url="https://dlcdn.apache.org/maven/maven-3"
    local filename="apache-maven-${version}-bin.zip"
    local url="${base_url}/${version}/binaries/${filename}"

    # Check if the URL is valid
    if ! is_url_valid "${url}"; then
        echo_error "Invalid download URL: ${url}"
        return 1
    fi

    # Check for cached file or, download afresh
    if ! _valid_cached_file "${filename}"; then
        echo_info "Downloading Maven version $version from $url..."
        curl -o "${CACHE_DIR}/${filename}" -L "${url}" || {
            echo_error "Failed to download from ${url}"
            return 1
        }

        echo_info "Download completed. File: ${filename}"
    else
        echo_info "Using cached Maven version $version package..."
    fi

    filename="${CACHE_DIR}/${filename}"

    # Install the Maven binary package
    _install_maven "${filename}" "${version}"
}

install_direnv() {
    echo_info "Installing direnv..."
    export bin_path=${HOME}/.local/bin
    mkdir -p ${bin_path}
    curl -fsSL https://direnv.net/install.sh | bash
    unset bin_path

    if [ ! -d ${HOME}/.config/direnv ]; then
        cp -r ${HOME}/.udkit/skel/direnv ${HOME}/.config/
    fi
}

install_starship() {
    echo_info "Installing starship..."
    mkdir -p ${HOME}/.local/bin
    curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ${HOME}/.local/bin

    if [ ! -f ${HOME}/.config/starship.toml ]; then
        cp ${HOME}/.udkit/skel/starship.toml ${HOME}/.config/
    fi
}

## Install the required devkit with commandline arguments
setup_devkit() {
    local devkit=$1
    local version=$2
    local force=${3:-false}

    if [[ -z $(command -v direnv 2>/dev/null) ]]; then
        install_direnv
    fi

    if [[ -z $(command -v starship 2>/dev/null) ]]; then
        install_starship
    fi

    case "$devkit" in
    python)
        setup_python $version $force
        ;;
    openjdk)
        setup_openjdk $version $force
        ;;
    nodejs)
        setup_nodejs $version $force
        ;;
    golang)
        setup_golang $version $force
        ;;
    gradle)
        setup_gradle $version $force
        ;;
    maven)
        setup_maven $version $force
        ;;
    *)
        echo_error "Unknown devkit: $devkit.\nSupported devkits: python, openjdk, nodejs, golang, gradle, maven"
        return 1
        ;;
    esac
}

## Parse cli arguments
FORCE=false
KIT_NAME=""
KIT_VERSION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
    --kit=*)
        KIT_NAME="${1#*=}"
        echo "Devkit: $KIT_NAME"
        shift
        ;;
    --version=*)
        KIT_VERSION="${1#*=}"
        echo "Version: $KIT_VERSION"
        shift
        ;;
    --force=*)
        FORCE="${1#*=}"
        echo "Force: $FORCE"
        shift
        ;;
    --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --kit=<devkit>      Devkit to install (python, openjdk, nodejs, golang, gradle, maven)"
        echo "  --version=<version> Version of the devkit to install"
        echo "  --force=<true|false> Force install devkit even if it is already installed"
        echo "  --help              Display this help message"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

if [[ $FORCE == "true" ]]; then
    setup_devkit $KIT_NAME $KIT_VERSION true
else
    setup_devkit $KIT_NAME $KIT_VERSION
fi
