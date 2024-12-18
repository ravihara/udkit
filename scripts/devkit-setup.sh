#!/bin/bash -e

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
