#!/bin/bash

# Homarr LXC Deploy Script with Network Prompt and Safety Checks

set -e

# Variables
TEMPLATE="debian-12-standard_12.0-1_amd64.tar.zst"
STORAGE="local"
CTID=105
HOSTNAME="homarr"
MEMORY=1024
DISK=8
CPU=2

# Prompt for Network Bridge
read -p "Enter Proxmox network bridge (e.g., vmbr0, vmbr1): " BRIDGE
if [ -z "$BRIDGE" ]; then
  echo "No bridge specified. Exiting."
  exit 1
fi

# Check if template exists
if [ ! -f "/var/lib/vz/template/cache/$TEMPLATE" ]; then
  echo "Downloading Debian template..."
  wget -O "/var/lib/vz/template/cache/$TEMPLATE" "https://images.linuxcontainers.org/images/debian/bookworm/amd64/default/20240228_05:24/rootfs.tar.xz"
  echo "Download complete."
fi

# Create the container
pct create $CTID \
  $STORAGE:vztmpl/$TEMPLATE \
  -hostname $HOSTNAME \
  -memory $MEMORY \
  -cores $CPU \
  -net0 name=eth0,bridge=$BRIDGE,firewall=1 \
  -rootfs $STORAGE:$DISK \
  -password homarr \
  -unprivileged 1

# Start the container
pct start $CTID

# Install Homarr inside the container
echo "Waiting for container to boot..."
sleep 10

pct exec $CTID -- bash -c "apt update && apt upgrade -y"
pct exec $CTID -- bash -c "apt install -y curl sudo docker.io docker-compose"

# Create Homarr directory
pct exec $CTID -- mkdir -p /opt/homarr

# Download and run Homarr docker-compose file
pct exec $CTID -- bash -c "curl -fsSL https://raw.githubusercontent.com/ajnart/homarr/main/docker-compose.yml -o /opt/homarr/docker-compose.yml"

pct exec $CTID -- bash -c "cd /opt/homarr && docker compose up -d"

IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')
echo "\n🎯 Homarr deployed! Access it at: http://$IP:7575"
