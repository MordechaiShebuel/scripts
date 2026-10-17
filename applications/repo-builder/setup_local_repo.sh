#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------
# Configuration – change these if needed
# ---------------------------------------------------------------
REPO_HOST="10.0.0.147"          # or "server.lan"
REPO_PORT="8080"
REPO_URL="http://${REPO_HOST}:${REPO_PORT}"

CONF_FILE="/etc/xbps.d/99-local-custom.conf"
# ---------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (or with sudo)"
    exit 1
fi

echo "==> Creating repository configuration: $CONF_FILE"
cat > "$CONF_FILE" << EOF
# Local custom Void repository
repository=${REPO_URL}
EOF

chmod 644 "$CONF_FILE"
echo "    repository=${REPO_URL}"

echo
echo "==> Synchronizing repositories (you will be asked to import the signing key)"
echo "    Verify the fingerprint carefully the first time!"
xbps-install -S

echo
echo "==> Done."
echo "You can now install packages from the local repository, e.g.:"
echo "    xbps-install -S <package>"
echo
echo "To list available packages from this repo only:"
echo "    xbps-query -M -R --repository=${REPO_URL} -s ''"
