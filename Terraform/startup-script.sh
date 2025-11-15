#!/bin/bash

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

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Create docker group if not exists
groupadd docker 2>/dev/null

# Add default GCE user
DEFAULT_USER=$(whoami)
usermod -aG docker $DEFAULT_USER

# Also add ubuntu user (GCE often uses this)
usermod -aG docker ubuntu 2>/dev/null

# Fix socket permissions (correct & secure)
chown root:docker /var/run/docker.sock 2>/dev/null || true
chmod 660 /var/run/docker.sock 2>/dev/null || true

# OPTIONAL: Initialize Docker Swarm (only on Manager)
# Uncomment if this is the Manager node
# docker swarm init --advertise-addr $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)


# ---------------------------
# Docker Swarm Initialization
# ---------------------------

# Detect Public IP (GCP internal metadata)
# PUBLIC_IP=$(curl -s -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

# # Initialize Swarm only on the first VM if not already initialized
# if [ "$(hostname)" = "manager-1" ]; then
#     docker swarm init --advertise-addr ${PUBLIC_IP}
#     docker swarm join-token worker -q > /tmp/worker_token
# fi

# Done
echo "Startup script completed."
