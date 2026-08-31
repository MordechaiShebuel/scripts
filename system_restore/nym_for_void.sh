#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root."
    exit 1
fi

echo "Installing dependencies..."

xbps-install -Syu

xbps-install -y \
    git \
    curl \
    rust \
    cargo \
    protobuf \
    protobuf-devel \
    pkg-config \
    libmnl-devel \
    libnftnl-devel \
    dbus \
    dbus-devel \
    openssl-devel \
    wireguard \
    wireguard-tools \
    iproute2 \
    go \
    glib-devel \
    gdk-devel \
    gtk+3-devel \
    libwebkit2gtk41-devel


for command in cargo wg ip modprobe; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Missing required command: $command"
        exit 1
    fi
done

if ! modprobe wireguard; then
    echo "The running kernel does not provide WireGuard support."
    echo "Install a WireGuard-capable kernel or the appropriate DKMS package."
    exit 1
fi

echo "Cloning or updating source tree..."

set -eu

repo=/usr/local/src/nym-vpn-client
release_tag="${1:-nym-vpn-v2026.12.3}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root."
    exit 1
fi

echo "Requested release: $release_tag"

mkdir -p /usr/local/src

if [ ! -d "$repo/.git" ]; then
    git clone https://github.com/nymtech/nym-vpn-client "$repo"
fi

cd "$repo"

git fetch --tags --force origin

if ! git rev-parse --verify --quiet "refs/tags/$release_tag" >/dev/null; then
    echo "Tag not found: $release_tag"
    echo
    echo "Available version-like tags:"
    git tag --list '*v*' --sort=-version:refname | head -30
    exit 1
fi

echo "Checking out $release_tag..."

git checkout --force "$release_tag"

echo "Checked out:"
git describe --tags --exact-match

pwd
echo "Making dependencies..."
make build-wireguard

echo "Building nym-vpnd..."

cd "$repo/nym-vpn-core"

cargo clean
cargo build --release --bin nym-vpnd

install -Dm755 \
    target/release/nym-vpnd \
    /usr/local/bin/nym-vpnd

echo "Daemon installed at /usr/local/bin/nym-vpnd"

echo "Creating daemon state directory..."

install -d -m 0755 /var/lib/nym-vpnd

echo "Creating runit service..."

install -d -m 0755 /etc/sv/nym-vpnd/log
install -d -m 0755 /var/log/nym-vpnd

cat > /etc/sv/nym-vpnd/run <<'EOF'
#!/bin/sh

exec 2>&1

cd /var/lib/nym-vpnd || exit 1

export RUST_LOG="${RUST_LOG:-info}"

# Run as root because WireGuard, routing, and DNS setup may require
# CAP_NET_ADMIN and other privileged operations.
exec /usr/local/bin/nym-vpnd -v run-as-service
EOF

chmod 0755 /etc/sv/nym-vpnd/run

cat > /etc/sv/nym-vpnd/log/run <<'EOF'
#!/bin/sh

mkdir -p /var/log/nym-vpnd
exec svlogd /var/log/nym-vpnd
EOF

chmod 0755 /etc/sv/nym-vpnd/log/run

echo "Enabling dbus..."

if [ ! -e /var/service/dbus ]; then
    ln -s /etc/sv/dbus /var/service/dbus
fi

echo "Enabling nym-vpnd..."

if [ ! -e /var/service/nym-vpnd ]; then
    ln -s /etc/sv/nym-vpnd /var/service/nym-vpnd
fi

sv up dbus
sv up nym-vpnd

echo
echo "Installation complete."
echo
sv status nym-vpnd
echo
echo "View logs with:"
echo "  sv tail nym-vpnd"

# Desktop app is built separately as native user:
# cd /usr/local/src/nym-vpn-client/nym-vpn-app

# sudo chown -R $USER .
# npm install
# npm run tauri build

# find src-tauri/target/release/bundle -type f -maxdepth 3

# Can exist in these sources
# src-tauri/target/release/bundle/appimage/
# src-tauri/target/release/bundle/deb/

# sudo install -Dm755 \
#     src-tauri/target/release/nym-vpn-app \
#     /usr/local/bin/nym-vpn-app

# sudo tee /usr/share/applications/nym-vpn-app.desktop << 'EOF'
# [Desktop Entry]
# Version=1.0
# Type=Application
# Name=Nym VPN App
# Comment=Privacy-focused VPN client
# Exec=/usr/local/bin/nym-vpn-app
# Icon=nym-vpn-app
# Terminal=false
# Categories=Utility;Network;
# EOF
