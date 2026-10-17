# Void Linux Custom Repository Builder

Build, sign, and serve your own Void Linux (XBPS) package repository using Podman.

This setup is especially useful for custom kernels, personal packages, or any packages you maintain outside the official Void repositories.

## Prerequisites

- Podman installed on the builder machine
- A signing key (RSA PEM) – generated once:
  ```bash
  ssh-keygen -t rsa -b 4096 -m PEM -f ~/private.pem
