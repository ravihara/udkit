#!/bin/bash -e

## Get the current script dir
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
UDKIT_BASE=$(cd -- "$(dirname -- "${SCRIPT_DIR}")" &>/dev/null && pwd)
CACHE_DIR="${UDKIT_BASE}/cache"

source ${UDKIT_BASE}/funcs.bash
mkdir -p $CACHE_DIR

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo_error "Do not run this script as root or with sudo."
    exit 1
fi

## Check for atleast two arguments
if [[ $# -lt 2 ]]; then
    echo_error "Usage: $(basename $0) --kit=<devkit> --version=<version> [--force=true|false]"
    exit 1
fi

_valid_cached_file() {
    filename=$1

    ## Check if the file is already cached and is not older than 30 days
    if [ -f "${CACHE_DIR}/${filename}" ]; then
        local last_modified=$(stat -c %Y "${CACHE_DIR}/${filename}")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_modified))
        local days_diff=$((time_diff / 86400))

        if [ $days_diff -lt 30 ]; then
            echo_info "Found already cached file $filename."
            return 0
        else
            echo_info "Cached file $filename is older than 30 days. Redownloading..."
            rm -f "${CACHE_DIR}/${filename}"
        fi
    fi

    return 1
}

_install_openjdk() {
    local pkgfile=$1
    local version=$2
    local force=$3

    local jdk_base="${UDKIT_BASE}/dist/openjdk"
    local pkgbase=$(tar_gz_pkgbase $pkgfile)

    mkdir -p $jdk_base

    local jdk_dir="${jdk_base}/${pkgbase}"
    local jdk_bin="${jdk_dir}/bin"
    local jdk_lib="${jdk_dir}/lib"
    local jdk_inc="${jdk_dir}/include"

    if [ "$force" != "true" ]; then
        if [ -d "${jdk_dir}" ]; then
            echo_info "Temurin JDK ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Temurin JDK ${version}..."
        rm -f "${jdk_base}/${version}"
        rm -rf "${jdk_dir}"
    fi

    echo_info "Installing Temurin JDK ${version}..."
    tar -xf "${pkgfile}" -C "${jdk_base}" && sync
    ln -s "${jdk_dir}" "${jdk_base}/${version}"

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
    local force=$3

    local node_base="${UDKIT_BASE}/dist/nodejs"
    local pkgbase=$(tar_pkgbase $pkgfile)

    mkdir -p $node_base

    local node_dir="${node_base}/${version}"
    local node_bin="${node_dir}/bin"
    local node_lib="${node_dir}/lib"
    local node_inc="${node_dir}/include"

    if [ "$force" != "true" ]; then
        if [ -d "${node_dir}" ]; then
            echo_info "Node.js ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Node.js ${version}..."
        rm -rf "${node_dir}"
    fi

    echo_info "Installing Node.js ${version}..."
    tar -xf "${pkgfile}" -C "${node_base}" && sync
    mv "${node_base}/${pkgbase}" "${node_dir}"

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
    local force=$3

    local go_base="${UDKIT_BASE}/dist/golang"
    local pkgbase=$(tar_gz_pkgbase $pkgfile)

    mkdir -p $go_base

    local go_dir="${go_base}/${version}"
    local go_bin="${go_dir}/bin"
    local go_lib="${go_dir}/lib"

    if [ "$force" != "true" ]; then
        if [ -d "${go_dir}" ]; then
            echo_info "Go ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Go ${version}..."
        rm -rf "${go_dir}"
    fi

    echo_info "Installing Go ${version}..."
    tar -zxf "${pkgfile}" -C "${go_base}" && sync
    mv "${go_base}/${pkgbase}" "${go_dir}"

    if [ -d "${go_bin}" ] && [ -d "${go_lib}" ]; then
        echo_info "Go ${version} is installed successfully."
    else
        echo_error "Failed to install Go ${version}."
        return 1
    fi
}

_install_gradle() {
    local pkgfile=$1
    local version=$2
    local force=$3

    local gradle_base="${UDKIT_BASE}/dist/gradle"
    local pkgbase=$(zip_pkgbase $pkgfile)

    mkdir -p $gradle_base

    local gradle_dir="${gradle_base}/${version}"
    local gradle_bin="${gradle_dir}/bin"
    local gradle_lib="${gradle_dir}/lib"

    if [ "$force" != "true" ]; then
        if [ -d "${gradle_dir}" ]; then
            echo_info "Gradle ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Gradle ${version}..."
        rm -rf "${gradle_dir}"
    fi

    echo_info "Installing Gradle ${version}..."
    unzip -qq "${pkgfile}" -d "${gradle_base}" && sync
    mv "${gradle_base}/${pkgbase}" "${gradle_dir}"

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
    local force=$3

    local maven_base="${UDKIT_BASE}/dist/maven"
    local pkgbase=$(zip_pkgbase $pkgfile)

    mkdir -p $maven_base

    local maven_dir="${maven_base}/${version}"
    local maven_bin="${maven_dir}/bin"
    local maven_lib="${maven_dir}/lib"

    if [ "$force" != "true" ]; then
        if [ -d "${maven_dir}" ]; then
            echo_info "Maven ${version} is already installed."
            return 0
        fi
    else
        echo_info "Force installing Maven ${version}..."
        rm -rf "${maven_dir}"
    fi

    echo_info "Installing Maven ${version}..."
    unzip -qq "${pkgfile}" -d "${maven_base}" && sync
    mv "${maven_base}/${pkgbase}" "${maven_dir}"

    if [ -d "${maven_bin}" ] && [ -d "${maven_lib}" ]; then
        echo_info "Maven ${version} is installed successfully."
    else
        echo_error "Failed to install Maven ${version}."
        return 1
    fi
}

# Function to download Temurin JDK
setup_openjdk() {
    local version=$1
    local force=$2

    if [[ -z $version ]]; then
        echo_error "Usage: $(basename $0) openjdk <version>"
        return 1
    fi

    # Detect OS and architecture
    local os=""
    local arch=""

    case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="mac" ;;
    *)
        echo_error "Unsupported OS: $(uname -s)"
        return 1
        ;;
    esac

    case "$(uname -m)" in
    x86_64) arch="x64" ;;
    aarch64 | arm64) arch="aarch64" ;;
    *)
        echo_error "Unsupported architecture: $(uname -m)"
        return 1
        ;;
    esac

    # Construct the download URL
    local base_url="https://api.adoptium.net/v3/binary/latest"
    local package_type="jdk"
    local jvm_impl="hotspot"
    local url="${base_url}/${version}/ga/${os}/${arch}/$package_type/${jvm_impl}/normal/adoptium"
    local filename="temurin-jdk-${version}-${os}-${arch}.tar.gz"

    # Check if URL is valid
    if ! is_url_valid "${url}"; then
        echo_error "Invalid download URL: ${url}"
        return 1
    fi

    # Check for cached file or, download afresh
    if ! _valid_cached_file "${filename}"; then
        echo_info "Downloading Temurin JDK ${version} for ${os}-${arch}..."
        curl -o "${CACHE_DIR}/${filename}" -L "${url}" || {
            echo_error "Failed to download from ${url}"
            return 1
        }

        echo_info "Download completed. File: ${filename}"
    else
        echo_info "Using cached Temurin JDK ${version} package for ${os}-${arch}..."
    fi

    filename="${CACHE_DIR}/${filename}"

    # Install the OpenJDK tarball
    _install_openjdk "${filename}" "${version}" "${force}"
}

# Function to download Node.js binary package
setup_nodejs() {
    local version=$1
    local force=$2

    if [[ -z $version ]]; then
        echo_error "Usage: setup_nodejs <version>"
        return 1
    fi

    # Detect OS and architecture
    local os=""
    local arch=""

    case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
        echo_error "Unsupported OS: $(uname -s)"
        return 1
        ;;
    esac

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
    local filename="node-v${version}-${os}-${arch}.tar.xz"
    local url="${base_url}/v${version}/${filename}"

    # Check if the URL is valid
    if ! is_url_valid "${url}"; then
        echo_error "Invalid download URL: ${url}"
        return 1
    fi

    # Check for cached file or, download afresh
    if ! _valid_cached_file "${filename}"; then
        echo_info "Downloading Node.js version ${version} for ${os}-${arch}..."
        curl -o "${CACHE_DIR}/${filename}" -L "${url}" || {
            echo_error "Failed to download from ${url}"
            return 1
        }

        echo_info "Download completed. File: ${filename}"
    else
        echo_info "Using cached Node.js version ${version} package for ${os}-${arch}..."
    fi

    filename="${CACHE_DIR}/${filename}"

    # Install the Node.js tarball
    _install_nodejs "${filename}" "${version}" "${force}"
}

# Function to download Go
setup_golang() {
    local version=$1
    local force=$2

    if [[ -z $version ]]; then
        echo_error "Usage: setup_golang <version>"
        return 1
    fi

    # Detect OS and architecture
    local os=""
    local arch=""

    case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
        echo_error "Unsupported OS: $(uname -s)"
        return 1
        ;;
    esac

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
    local filename="go${version}.${os}-${arch}.tar.gz"
    local url="${base_url}/${filename}"

    # Check if the URL is valid
    if ! is_url_valid "${url}"; then
        echo_error "Invalid download URL: ${url}"
        return 1
    fi

    # Check for cached file or, download afresh
    if ! _valid_cached_file "${filename}"; then
        echo_info "Downloading Go version ${version} for ${os}-${arch}..."
        curl -o "${CACHE_DIR}/${filename}" -L "${url}" || {
            echo_error "Failed to download from ${url}"
            return 1
        }

        echo_info "Download completed. File: ${filename}"
    else
        echo_info "Using cached Go version ${version} package for ${os}-${arch}..."
    fi

    filename="${CACHE_DIR}/${filename}"

    # Install the Go binary
    _install_golang "${filename}" "${version}" "${force}"
}

# Function to download Gradle binary package
setup_gradle() {
    local version=$1
    local force=$2

    # Check if version is provided
    if [[ -z "$version" ]]; then
        echo_error "Error: Please provide the Gradle version as an argument."
        return 1
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
    _install_gradle "${filename}" "${version}" "${force}"
}

# Function to download Maven binary package
setup_maven() {
    local version=$1
    local force=$2

    # Check if version is provided
    if [[ -z "$version" ]]; then
        echo_error "Error: Please provide the Maven version as an argument."
        return 1
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
    _install_maven "${filename}" "${version}" "${force}"
}

install_direnv() {
    echo_info "Installing direnv..."
    export bin_path=${HOME}/.local/bin
    mkdir -p ${bin_path}
    curl -fsSL https://direnv.net/install.sh | bash
    unset bin_path

    if [ ! -d ${HOME}/.config/direnv ]; then
        cp -a ${UDKIT_BASE}/skel/direnv ${HOME}/.config/
    fi
}

install_starship() {
    echo_info "Installing starship..."
    mkdir -p ${HOME}/.local/bin
    curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ${HOME}/.local/bin

    if [ ! -f ${HOME}/.config/starship.toml ]; then
        cp ${UDKIT_BASE}/skel/starship.toml ${HOME}/.config/
    fi
}

## Install the required devkit with commandline arguments
setup_devkit() {
    local devkit=$1
    local version=$2
    local force=$3

    if [[ -z $(command -v direnv 2>/dev/null) ]]; then
        install_direnv
    fi

    if [[ -z $(command -v starship 2>/dev/null) ]]; then
        install_starship
    fi

    case "$devkit" in
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
        echo_error "Unknown devkit: $devkit.\nSupported devkits: openjdk, nodejs, golang, gradle, maven"
        return 1
        ;;
    esac
}

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
        echo "  --kit=<devkit>      Devkit to install (openjdk, nodejs, golang, gradle, maven)"
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
