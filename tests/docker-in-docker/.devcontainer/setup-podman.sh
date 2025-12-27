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

# Create /var/run/docker.sock via podman socket
echo "Setting up Podman socket..."
systemctl --user enable --now podman.socket || true

# Create symlink for /var/run/docker.sock (if running as root)
if [ "$(id -u)" = "0" ]; then
    sudo systemctl enable --now podman.socket
    sudo ln -sf /run/podman/podman.sock /var/run/docker.sock
else
    # For rootless, create user socket link
    mkdir -p /run/user/$(id -u)
    podman system service --time=0 unix:///run/user/$(id -u)/podman/podman.sock &
    sleep 2
fi

# Verify installation
echo "=== Verification ==="
echo "docker command:"
docker --version
echo ""
echo "Checking if this is really Podman:"
docker version 2>&1 | grep -i podman && echo "✅ Confirmed: docker command is using Podman" || echo "⚠️ Check failed"
echo ""
echo "Podman info:"
podman --version

