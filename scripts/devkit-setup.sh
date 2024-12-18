#!/bin/bash -e

# Function to download OpenJDK Temurin
download_openjdk() {
    local version="$1"
    local architecture="$2"
    local os="linux" # Default to Linux, update if needed (e.g., "mac" for macOS)
    local base_url="https://api.adoptium.net/v3/binary/latest"

    if [[ -z "$version" || -z "$architecture" ]]; then
        echo "Usage: download_temurin <version> <architecture>"
        echo "Example: download_temurin 17 x64"
        return 1
    fi

    # Construct the download URL
    local url="${base_url}/${version}/ga/${os}/${architecture}/jdk/hotspot/normal/adoptium"

    # Define the output file
    local output_file="OpenJDK-Temurin-${version}-${architecture}.tar.gz"

    echo "Downloading OpenJDK Temurin version ${version} for ${architecture} architecture..."
    curl -L -o "${output_file}" "${url}"

    if [[ $? -eq 0 ]]; then
        echo "Download complete: ${output_file}"
    else
        echo "Failed to download OpenJDK Temurin. Please check the version and architecture."
        return 2
    fi
}

# Function to download Node.js binary package
download_nodejs() {
    local version="$1"     # Node.js version to download
    local arch="${2:-x64}" # Architecture (default: x64)
    local base_url="https://nodejs.org/dist"
    local filename="node-v${version}-linux-${arch}.tar.xz"
    local url="${base_url}/v${version}/${filename}"

    # Check if version is provided
    if [[ -z "$version" ]]; then
        echo "Usage: download_nodejs <version> [architecture]"
        echo "Example: download_nodejs 18.18.0 x64"
        return 1
    fi

    echo "Downloading Node.js version ${version} for Linux (${arch})..."

    # Use curl or wget to download
    if command -v curl >/dev/null; then
        curl -O "$url"
    elif command -v wget >/dev/null; then
        wget "$url"
    else
        echo "Error: Neither curl nor wget is installed."
        return 1
    fi

    # Check if the download was successful
    if [[ -f "$filename" ]]; then
        echo "Download complete: ${filename}"
    else
        echo "Error: Failed to download Node.js version ${version}."
        return 1
    fi

    echo "To extract: tar -xf ${filename}"
    return 0
}

# Function to download Go
download_golang() {
    # Function to download and install Go
    # Arguments:
    # $1 - Version (e.g., "1.20.5")
    # $2 - Architecture (e.g., "amd64", "arm64")

    if [[ $# -ne 2 ]]; then
        echo "Usage: download_golang <version> <architecture>"
        return 1
    fi

    local version="$1"
    local arch="$2"
    local url="https://go.dev/dl/go${version}.linux-${arch}.tar.gz"
    local destination="/usr/local"

    echo "Downloading Go version ${version} for architecture ${arch} from ${url}..."

    # Download the tarball
    wget -q --show-progress "${url}" -O "/tmp/go${version}.linux-${arch}.tar.gz"
    if [[ $? -ne 0 ]]; then
        echo "Failed to download Go. Please check the version and architecture."
        return 1
    fi

    echo "Download successful. Installing to ${destination}..."

    # Remove any existing Go installation in /usr/local
    sudo rm -rf "${destination}/go"

    # Extract the tarball to /usr/local
    sudo tar -C "${destination}" -xzf "/tmp/go${version}.linux-${arch}.tar.gz"

    # Clean up the tarball
    rm "/tmp/go${version}.linux-${arch}.tar.gz"

    echo "Go ${version} installed successfully to ${destination}/go."
    echo "Add the following line to your shell configuration file:"
    echo 'export PATH=$PATH:/usr/local/go/bin'
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
