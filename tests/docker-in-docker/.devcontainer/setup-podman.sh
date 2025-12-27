#!/bin/bash
set -e

echo "=== Setting up Podman as Docker replacement ==="

# Remove Docker if installed
if command -v docker &> /dev/null; then
    echo "Removing Docker..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
    sudo apt-get autoremove -y || true
fi

# Install Podman and podman-docker
echo "Installing Podman and podman-docker..."
sudo apt-get update
sudo apt-get install -y podman podman-docker

# Verify installation
echo ""
echo "=== Verification ==="
echo "docker --version:"
docker --version

echo ""
echo "podman --version:"
podman --version

echo ""
echo "Checking if docker is really Podman:"
if docker version 2>&1 | grep -qi podman; then
    echo "✅ Confirmed: docker command is using Podman"
else
    echo "⚠️ Verification check - docker version output:"
    docker version 2>&1 || true
fi
