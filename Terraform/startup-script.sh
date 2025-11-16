#!/bin/bash

set -e

# Update system
apt-get update -y

# Install dependencies
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Ensure docker group exists (Docker normally creates it)
groupadd -f docker

# ----- ADD USERS TO DOCKER GROUP -----

# Add ubuntu user if it exists (common on GCE)
if id "ubuntu" >/dev/null 2>&1; then
    usermod -aG docker ubuntu
fi

# If a user was created via metadata (GCE), add them too
GCE_USER=$(getent passwd 1000 | cut -d: -f1)
if [ -n "$GCE_USER" ]; then
    usermod -aG docker "$GCE_USER"
fi

# No need to modify root — root already has full access

echo "Docker installation and user setup complete."
