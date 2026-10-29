# To build the repo image:
podman-compose build

# To start the repo server:
podman-compose up -d

# View build logs:
podman-compose logs -f void-repo-builder

# Setup repo on other machines:
# From another Void Linux system, add to /etc/xbps.d/
echo 'repository=http://server.lan:8000' | sudo tee /etc/xbps.d/90-local.conf
xbps-install -S
