# Homarr LXC Deploy Script

This repository contains a simple and safe script to deploy a Homarr dashboard inside an LXC container on Proxmox.

## Usage

### Download the script
```bash
curl -O https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/homarr-lxc-deploy/main/homarr-deploy.sh
```

### Make the script executable
```bash
chmod +x homarr-deploy.sh
```

### Run the script
```bash
./homarr-deploy.sh
```

You will be prompted to enter your Proxmox network bridge (e.g., vmbr0, vmbr1).

Once deployed, access your Homarr dashboard at:
```
http://<Container-IP>:7575
```
