#!/bin/bash

set -e

echo "====== Updating system ======"
apt update -y
apt upgrade -y

echo "====== Installing Docker (docker.io) ======"
apt install -y docker.io

echo "====== Enabling & starting Docker ======"
systemctl enable docker
systemctl start docker

echo "====== Adding current user to docker group ======"
# Automatically detects the current login user
CURRENT_USER=$(logname)
usermod -aG docker $CURRENT_USER

echo "====== Fixing docker.sock permission issue ======"
# Sometimes docker.sock gets reset after reboot or install
chmod 666 /var/run/docker.sock

echo "====== Restarting Docker ======"
systemctl restart docker

echo "====== Docker Installation Completed Successfully ======"
echo "NOTE: You must log out and login again for group changes to apply."
