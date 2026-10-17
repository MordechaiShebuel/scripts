#!/bin/bash
# serve_repo.sh – run on the host (or inside another container)

REPO_DIR="${1:-$HOME/src/binpkgs}"
PORT="${2:-8080}"

if [[ ! -d "$REPO_DIR" ]]; then
    echo "Repository directory $REPO_DIR does not exist"
    exit 1
fi

echo "Serving $REPO_DIR on http://0.0.0.0:$PORT"
echo "On client machines create /etc/xbps.d/99-local.conf containing:"
echo "  repository=http://$(hostname -I | awk '{print $1}'):$PORT"
echo
cd "$REPO_DIR"
exec python3 -m http.server "$PORT" --bind 0.0.0.0
