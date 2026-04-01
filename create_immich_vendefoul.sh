#!/bin/bash

apt update && apt upgrade -y

# Install Podman
apt install -y podman podman-compose

# Enable and start the Podman service (for rootful mode; recommended for servers)
rc-update add podman
rc-service podman start

# Optional: Allow a non-root user to run podman (rootless) - add your user
# usermod -aG podman $USER   # then log out/in
