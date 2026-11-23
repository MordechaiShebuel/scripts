#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo: sudo bash $0" >&2
    exit 1
fi

if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
    echo "Run this with sudo from the account that installed NymVPN." >&2
    exit 1
fi

USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
APP="$USER_HOME/.local/share/bin/NymVPN.AppImage"
APP_DESKTOP="$USER_HOME/.local/share/applications/nym-vpn.desktop"
DAEMON_SOURCE="$USER_HOME/.local/share/bin/nym-vpnd"
DAEMON="/usr/local/bin/nym-vpnd"
UNIT="/etc/systemd/system/nym-vpnd.service"

[[ -x "$APP" ]] || { echo "AppImage not found or not executable: $APP" >&2; exit 1; }
[[ -f "$APP_DESKTOP" ]] || { echo "Desktop entry not found: $APP_DESKTOP" >&2; exit 1; }
[[ -f "$UNIT" ]] || { echo "Service unit not found: $UNIT" >&2; exit 1; }

# Put the privileged daemon in a system-wide writable location.
if [[ -f "$DAEMON_SOURCE" ]]; then
    install -D -m 755 "$DAEMON_SOURCE" "$DAEMON"
elif [[ ! -x "$DAEMON" ]]; then
    echo "Daemon not found at $DAEMON_SOURCE or $DAEMON" >&2
    exit 1
fi

cp -a "$UNIT" "$UNIT.bak"
cp -a "$APP_DESKTOP" "$APP_DESKTOP.bak"

sed -i "s|^ExecStart=.*|ExecStart=$DAEMON|" "$UNIT"
sed -i "s|^Exec=.*|Exec=env RUST_LOG=info,nym_vpn_app=debug $APP -l %U|" "$APP_DESKTOP"

systemctl daemon-reload
systemctl restart nym-vpnd

echo "Updated service and desktop entry."
systemctl --no-pager --full status nym-vpnd
