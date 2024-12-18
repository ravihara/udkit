#!/bin/bash -e

source ~/.udkit/funcs.bash

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo_error "Do not run this script as root or with sudo."
fi

# Function to download OpenJDK Temurin
download_temurin() {
    local version=$1
    if [[ -z $version ]]; then
        echo "Usage: download_temurin <version>"
        return 1
    fi

    # Detect OS and architecture
    local os=""
    local arch=""

    case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="mac" ;;
    *)
        echo "Unsupported OS: $(uname -s)"
        return 1
        ;;
    esac

    case "$(uname -m)" in
    x86_64) arch="x64" ;;
    aarch64 | arm64) arch="aarch64" ;;
    *)
        echo "Unsupported architecture: $(uname -m)"
        return 1
        ;;
    esac

    # Construct the download URL
    local base_url="https://api.adoptium.net/v3/binary/latest"
    local package_type="jdk"
    local jvm_impl="hotspot"
    local url="${base_url}/${version}/ga/${os}/${arch}/$package_type/${jvm_impl}/normal/adoptium"
    local outfile="temurin-${version}-${os}-${arch}.tar.gz"

    # Download the JDK
    echo_info "Downloading Temurin JDK version ${version} for ${os}-${arch}..."
    curl -o "${outfile}" -L "${url}" || {
        echo "Failed to download from ${url}"
        return 1
    }

    echo_info "Download completed. File: ${outfile}"
    local pkg_rootdir=$(tar -ztf $outfile | head -1 | sed -e 's|\/$||')
}

# Function to download Node.js binary package
download_nodejs() {
    local version=$1
    if [[ -z $version ]]; then
        echo "Usage: download_nodejs <version>"
        return 1
    fi

    # Detect OS and architecture
    local os=""
    local arch=""

    case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
        echo "Unsupported OS: $(uname -s)"
        return 1
        ;;
    esac

    case "$(uname -m)" in
    x86_64) arch="x64" ;;
    arm64 | aarch64) arch="arm64" ;;
    *)
        echo "Unsupported architecture: $(uname -m)"
        return 1
        ;;
    esac

    # Construct the download URL
    local base_url="https://nodejs.org/dist"
    local filename="node-v${version}-${os}-${arch}.tar.gz"
    local url="${base_url}/v${version}/${filename}"

    # Download the Node.js tarball
    echo "Downloading Node.js version ${version} for ${os}-${arch}..."
    curl -LO "${url}" || {
        echo "Failed to download from ${url}"
        return 1
    }

    echo "Download completed. File: ${filename}"
}

# Function to download Go
download_golang() {
    local version=$1
    if [[ -z $version ]]; then
        echo "Usage: download_golang <version>"
        return 1
    fi

    # Detect OS and architecture
    local os=""
    local arch=""

    case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
        echo "Unsupported OS: $(uname -s)"
        return 1
        ;;
    esac

    case "$(uname -m)" in
    x86_64) arch="amd64" ;;
    arm64 | aarch64) arch="arm64" ;;
    *)
        echo "Unsupported architecture: $(uname -m)"
        return 1
        ;;
    esac

    # Construct the download URL
    local base_url="https://go.dev/dl"
    local filename="go${version}.${os}-${arch}.tar.gz"
    local url="${base_url}/${filename}"

    # Download the Go tarball
    echo "Downloading Go version ${version} for ${os}-${arch}..."
    curl -LO "${url}" || {
        echo "Failed to download from ${url}"
        return 1
    }

    echo "Download completed. File: ${filename}"
}

# Function to download Gradle binary package
download_gradle() {
    local version=$1
    local download_url="https://services.gradle.org/distributions/gradle-${version}-bin.zip"
    local output_file="gradle-${version}-bin.zip"

    # Check if version is provided
    if [[ -z "$version" ]]; then
        echo "Error: Please provide the Gradle version as an argument."
        return 1
    fi

    # Download the Gradle binary package
    echo "Downloading Gradle version $version from $download_url..."
    curl -o "$output_file" "$download_url" --fail

    # Check if the download was successful
    if [[ $? -eq 0 ]]; then
        echo "Download completed: $output_file"
    else
        echo "Error: Failed to download Gradle version $version. Please check the version and try again."
        return 1
    fi
}

# Function to download Maven binary package
download_maven() {
    local version=$1
    local download_url="https://dlcdn.apache.org/maven/maven-3/${version}/binaries/apache-maven-${version}-bin.zip"
    local output_file="apache-maven-${version}-bin.zip"

    # Check if version is provided
    if [[ -z "$version" ]]; then
        echo "Error: Please provide the Maven version as an argument."
        return 1
    fi

    # Download the Maven binary package
    echo "Downloading Maven version $version from $download_url..."
    curl -o "$output_file" "$download_url" --fail

    # Check if the download was successful
    if [[ $? -eq 0 ]]; then
        echo "Download completed: $output_file"
    else
        echo "Error: Failed to download Maven version $version. Please check the version and try again."
        return 1
    fi
}
