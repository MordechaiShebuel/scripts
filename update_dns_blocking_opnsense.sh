#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG ======
BLOCKLIST_URL="https://raw.githubusercontent.com/d3ward/toolz/master/src/d3host.adblock"
TMPDIR="/tmp/opnsense-blocklist"
OUTFILE="hosts-blocklist.txt"                        # local name
DEST_USER="root"                                     # change if not root
DEST_HOST="10.0.0.1"                   # change to your OPNsense IP/host
DEST_PATH="/usr/local/etc/hosts-blocklist"           # destination path on OPNsense
SSH_PORT=22                                          # change if nonstandard
# ====================
# Version 1.0

mkdir -p "$TMPDIR"
cd "$TMPDIR"

echo "Downloading $BLOCKLIST_URL..."
curl -fsSL "$BLOCKLIST_URL" -o raw-blocklist.txt

echo "Converting to hosts format..."
# Remove adblock markers, comments, protocols, paths, ports; extract domains only.
sed -E 's/\r$//' raw-blocklist.txt \
  | sed -E 's!^\|\|!!; s!^\|!!; s!^\^.*$!!; s!^\*.*$!!' \
  | sed -E 's#^https?://##I; s#/.*$##; s/:[0-9]+$//' \
  | sed -E 's/#.*$//' \
  | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//' \
  | sed -E 's/^\.//' \
  | grep -E '^[A-Za-z0-9._-]+\.[A-Za-z]{2,}$' \
  | awk '{print tolower($0)}' \
  | sort -u \
  | sed -E 's/^/0.0.0.0 /' > "$OUTFILE"

echo "Lines in final hosts file: $(wc -l < "$OUTFILE")"

echo "Copying to ${DEST_USER}@${DEST_HOST}:${DEST_PATH} (via /tmp, port $SSH_PORT)..."
scp -P "$SSH_PORT" -o StrictHostKeyChecking=accept-new "$OUTFILE" "${DEST_USER}@${DEST_HOST}:/tmp/${OUTFILE}.tmp"

echo "Moving file into place on OPNsense (requires privileges)..."
ssh -p "$SSH_PORT" -o StrictHostKeyChecking=accept-new "${DEST_USER}@${DEST_HOST}" sh -s <<'EOF'
set -e
OUT="/tmp/hosts-blocklist.txt.tmp"
DEST="/usr/local/etc/hosts-blocklist"
if [ -f "$OUT" ]; then
  mv "$OUT" "$DEST"
  chown root:wheel "$DEST" 2>/dev/null || true
  chmod 0644 "$DEST"
  echo "Updated $DEST on the OPNsense box."
else
  echo "Temporary file not found: $OUT" >&2
  exit 2
fi
EOF

echo "Done. Point Unbound to ${DEST_PATH} in the OPNsense GUI and restart Unbound."
