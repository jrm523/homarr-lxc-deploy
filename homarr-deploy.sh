#!/bin/bash

# Homarr LXC Deploy Script with Network Prompt and Safety Checks

set -e

# Variables
CTID=105
HOSTNAME="homarr"
MEMORY=1024
DISK=8
CPU=2
TEMPLATE_STORAGE="local"  # For container templates
ROOTFS_STORAGE="local-lvm" # For container disk storage
NAMESERVER="192.168.31.1" # Default DNS server

# Prompt for Network Bridge
read -p "Enter Proxmox network bridge (e.g., vmbr0, vmbr1): " BRIDGE
if [ -z "$BRIDGE" ]; then
  echo "No bridge specified. Exiting."
  exit 1
fi

# Get latest Debian template
echo "Fetching latest Debian template..."
pveam update
TEMPLATE=$(pveam available | grep debian-12-standard | sort -r | head -n 1 | awk '{print $2}')

if [ -z "$TEMPLATE" ]; then
  echo "No Debian template found. Exiting."
  exit 1
fi

# Download template if not already present
if [ ! -f "/var/lib/vz/template/cache/$TEMPLATE" ]; then
  echo "Downloading $TEMPLATE..."
  pveam download $TEMPLATE_STORAGE $TEMPLATE
  echo "Template download complete."
fi

# Create the container
pct create $CTID \
  $TEMPLATE_STORAGE:vztmpl/$TEMPLATE \
  -hostname $HOSTNAME \
  -memory $MEMORY \
  -cores $CPU \
  -net0 name=eth0,bridge=$BRIDGE,firewall=1 \
  -rootfs $ROOTFS_STORAGE:$DISK \
  -password homarr \
  -unprivileged 1
  -nameserver $NAMESERVER


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
