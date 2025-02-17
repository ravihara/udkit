#!/bin/bash

mkdir -p ~/.local/bin

pushd ~/.local/bin >/dev/null

## Removed existing kubectl and kubectl-convert
rm -f kubectl kubectl-convert && sync

## Download the kubectl and kubectl-convert
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"

## Validate the binaries with checksum
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert.sha256"

echo "$(cat kubectl.sha256) kubectl" | sha256sum --check
echo "$(cat kubectl-convert.sha256) kubectl-convert" | sha256sum --check

## Setup executable bit
chmod +x kubectl kubectl-convert
rm -f *.sha256 && sync

## Remove existing helm binary
rm -f helm && sync

## Install helm from installation script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
USE_SUDO=false HELM_INSTALL_DIR=$HOME/.local/bin ./get_helm.sh && sync

## Cleanup installation script
rm -f get_helm.sh

popd >/dev/null
