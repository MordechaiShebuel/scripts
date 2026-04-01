#!/bin/bash
# =============================================================================
# Plex Media Server Installation Script for Vendefoul Wolf Linux (Devuan + OpenRC)
#
# This script:
#   1. Downloads and sets up the official Plex repository + installs Plex Media Server
#   2. Installs Plex and configures it to run as the 'plex' user
#   3. Creates a proper OpenRC init script (/etc/init.d/plexmediaserver)
#   4. Enables the service on boot (default runlevel)
#   5. Ensures /home/media/* is readable by the Plex user
#
# Run as root:  sudo ./install-plex-vendefoul.sh
# =============================================================================

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)."
    exit 1
fi

echo "🚀 Starting Plex Media Server installation for Vendefoul Wolf (OpenRC)..."

# ----------------------------------------------------------------------------
# 1. Add official Plex Debian repository (works perfectly on Devuan)
# ----------------------------------------------------------------------------
echo "📥 Adding Plex GPG key and repository..."
curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key | \
    gpg --dearmor -o /usr/share/keyrings/plex-archive-keyring.gpg

cat > /etc/apt/sources.list.d/plexmediaserver.list << EOF
deb [signed-by=/usr/share/keyrings/plex-archive-keyring.gpg] https://downloads.plex.tv/repo/deb public main
EOF

apt-get update -qq

# ----------------------------------------------------------------------------
# 2. Install Plex Media Server
# ----------------------------------------------------------------------------
echo "📦 Installing Plex Media Server (this will also create the 'plex' user)..."
apt-get install -y plexmediaserver

# The package creates /etc/default/plexmediaserver and /usr/sbin/start_pms automatically

# ----------------------------------------------------------------------------
# 3. Create OpenRC-compatible init script (SysV style, fully supported by OpenRC)
# ----------------------------------------------------------------------------
echo "🔧 Creating OpenRC init script at /etc/init.d/plexmediaserver..."

cat > /etc/init.d/plexmediaserver << 'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          plexmediaserver
# Required-Start:    $remote_fs $syslog $networking
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Plex Media Server
# Description:       Plex Media Server for Linux
#                    More information at https://www.plex.tv
# Author:            Original by Cedric Quillevere, rewamped by Christian Svedin
#                    Adapted for Vendefoul Wolf / OpenRC
# Version:           1.2
### END INIT INFO

# Read configuration variable file if it is present
[ -r /etc/default/plexmediaserver ] && . /etc/default/plexmediaserver

# Plex package should have installed this
test -f "/usr/lib/plexmediaserver/start.sh" || test -f "/usr/sbin/start_pms" || exit 0

plex_running=$(ps ax | grep "[P]lex Media Server" | awk '{print $1}' | wc -l)

case "$1" in
    start)
        if [ "$plex_running" -gt 0 ]; then
            echo "Plex Media Server is already running."
            exit 0
        fi
        echo -n "Starting Plex Media Server: "
        su -l "$PLEX_MEDIA_SERVER_USER" -c "/usr/sbin/start_pms" >/dev/null 2>&1 &
        sleep 2
        echo "done"
        ;;
    stop)
        if [ "$plex_running" -eq 0 ]; then
            echo "Plex Media Server is not running."
            exit 0
        fi
        echo -n "Stopping Plex Media Server: "
        # Kill main process and plugins
        pkill -f "Plex Media Server" 2>/dev/null || true
        pkill -f "Plex DLNA Server" 2>/dev/null || true
        sleep 2
        echo "done"
        ;;
    restart)
        "$0" stop
        sleep 2
        "$0" start
        ;;
    status)
        if [ "$plex_running" -gt 0 ]; then
            echo "Plex Media Server is running."
        else
            echo "Plex Media Server is not running."
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
EOF

chmod +x /etc/init.d/plexmediaserver

# ----------------------------------------------------------------------------
# 4. Enable service on boot (OpenRC)
# ----------------------------------------------------------------------------
echo "🔄 Enabling Plex service at boot..."
rc-update add plexmediaserver default

# ----------------------------------------------------------------------------
# 5. Ensure /home/media/* is usable as media source
# ----------------------------------------------------------------------------
if [ -d "/home/media" ]; then
    echo "📂 Setting permissions so Plex can read /home/media/* ..."
    # Make directories traversable and files readable by everyone (standard for media servers)
    find /home/media -type d -exec chmod 755 {} + 2>/dev/null || true
    find /home/media -type f -exec chmod 644 {} + 2>/dev/null || true
    # Also give group read/execute if you prefer (optional)
    chgrp -R plex /home/media 2>/dev/null || true
    chmod -R g+rx /home/media 2>/dev/null || true
    echo "✅ /home/media permissions updated."
else
    echo "⚠️  /home/media directory not found. Create it and place your media files there."
    mkdir -p /home/media 2>/dev/null || true
    chmod 755 /home/media
fi

# ----------------------------------------------------------------------------
# 6. Start the service now
# ----------------------------------------------------------------------------
echo "▶️  Starting Plex Media Server..."
rc-service plexmediaserver start || echo "⚠️  Service start had warnings (normal on first run)."

# ----------------------------------------------------------------------------
# Final instructions
# ----------------------------------------------------------------------------
echo ""
echo "🎉 Plex Media Server is now installed and running on Vendefoul Wolf with OpenRC!"
echo ""
echo "📍 Access the Plex web UI at: http://$(hostname -I | awk '{print $1}'):32400/web"
echo "   (or http://localhost:32400/web if accessing from the same machine)"
echo ""
echo "Next steps:"
echo "   1. Open the link above in a browser and sign in with your Plex account."
echo "   2. Claim the server when prompted."
echo "   3. When adding libraries, use the path: /home/media"
echo "      (Plex will scan all subfolders like /home/media/Movies, /home/media/TV, etc.)"
echo ""
echo "Useful commands:"
echo "   sudo rc-service plexmediaserver start|stop|restart|status"
echo "   sudo rc-update del plexmediaserver default   # to disable at boot"
echo ""
echo "Updates: Just run 'apt-get update && apt-get upgrade plexmediaserver' in the future."
echo "Enjoy your media server! 🎬"
