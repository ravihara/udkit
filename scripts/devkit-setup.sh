#!/bin/bash -e

## Get the current script dir
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
UDKIT_BASE=$(cd -- "$(dirname -- "${SCRIPT_DIR}")" &>/dev/null && pwd)
CACHE_DIR="${UDKIT_BASE}/cache"

mkdir -p $CACHE_DIR
source ${UDKIT_BASE}/funcs.bash

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo_error "Do not run this script as root or with sudo."
    exit 1
fi

check_cached_file() {
    filename=$1

    ## Check if the file is already cached and is not older than 30 days
    if [ -f "${CACHE_DIR}/${filename}" ]; then
        local last_modified=$(stat -c %Y "${CACHE_DIR}/${filename}")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_modified))
        local days_diff=$((time_diff / 86400))
        if [ $days_diff -lt 30 ]; then
            echo_info "File is already cached and is not older than 30 days. Skipping download."
            return 0
        else
            echo_info "File is already cached but is older than 30 days. Downloading again."
            rm -f "${CACHE_DIR}/${filename}"
        fi
    fi

    return 1
}

# Function to download OpenJDK Temurin
download_temurin() {
    local version=$1
    if [[ -z $version ]]; then
        echo_error "Usage: download_temurin <version>"
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
    local filename="temurin-${version}-${os}-${arch}.tar.gz"

    # Download the JDK
    echo_info "Downloading Temurin JDK version ${version} for ${os}-${arch}..."
    curl -o "${filename}" -L "${url}" || {
        echo_error "Failed to download from ${url}"
        return 1
    }

    echo_info "Download completed. File: ${filename}"
    local pkg_rootdir=$(tar -ztf "${filename}" | head -1 | awk -F "/" {'print $1'})
}

# Function to download Node.js binary package
download_nodejs() {
    local version=$1
    if [[ -z $version ]]; then
        echo_error "Usage: download_nodejs <version>"
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

    # Download the Node.js tarball
    echo_info "Downloading Node.js version ${version} for ${os}-${arch}..."
    curl -o "${filename}" -L "${url}" || {
        echo_error "Failed to download from ${url}"
        return 1
    }

    echo_info "Download completed. File: ${filename}"
}

# Function to download Go
download_golang() {
    local version=$1
    if [[ -z $version ]]; then
        echo_error "Usage: download_golang <version>"
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

    # Download the Go tarball
    echo_info "Downloading Go version ${version} for ${os}-${arch}..."
    curl -o "${filename}" -L "${url}" || {
        echo_error "Failed to download from ${url}"
        return 1
    }

    echo_info "Download completed. File: ${filename}"
}

# Function to download Gradle binary package
download_gradle() {
    local version=$1
    local base_url="https://services.gradle.org/distributions"
    local filename="gradle-${version}-bin.zip"
    local url="${base_url}/${filename}"

    # Check if version is provided
    if [[ -z "$version" ]]; then
        echo_error "Error: Please provide the Gradle version as an argument."
        return 1
    fi

    # Download the Gradle binary package
    echo_info "Downloading Gradle version $version from $url..."
    curl -o "${filename}" -L "${url}" || {
        echo_error "Failed to download from ${url}"
        return 1
    }

    echo_info "Download completed. File: ${filename}"
}

# Function to download Maven binary package
download_maven() {
    local version=$1

    # Check if version is provided
    if [[ -z "$version" ]]; then
        echo_error "Error: Please provide the Maven version as an argument."
        return 1
    fi

    local base_url="https://dlcdn.apache.org/maven/maven-3"
    local filename="apache-maven-${version}-bin.zip"
    local url="${base_url}/${version}/binaries/${filename}"

    # Download the Maven binary package
    echo_info "Downloading Maven version $version from $url..."
    curl -o "${filename}" -L "${url}" || {
        echo_error "Failed to download from ${url}"
        return 1
    }

    echo_info "Download completed. File: ${filename}"
}

download_temurin 17
download_nodejs 22.12.0
download_golang 1.23.4
download_gradle 8.11
download_maven 3.9.9
