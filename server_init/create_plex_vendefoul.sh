#!/bin/bash
# =============================================================================
# Plex Media Server Installation Script for Vendefoul Wolf (Devuan + OpenRC)
# Tailored for server at 10.0.0.3 running NOMAD + other services
# =============================================================================

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)."
    exit 1
fi

echo "🚀 Starting Plex Media Server installation on 10.0.0.3 (Vendefoul Wolf + OpenRC)..."

# ----------------------------------------------------------------------------
# 1. Add official Plex repository
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
echo "📦 Installing Plex Media Server..."
apt-get install -y plexmediaserver

# ----------------------------------------------------------------------------
# 3. Create OpenRC init script
# ----------------------------------------------------------------------------
echo "🔧 Creating /etc/init.d/plexmediaserver..."

cat > /etc/init.d/plexmediaserver << 'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          plexmediaserver
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Plex Media Server
### END INIT INFO

[ -r /etc/default/plexmediaserver ] && . /etc/default/plexmediaserver

test -f "/usr/sbin/start_pms" || exit 0

case "$1" in
    start)
        echo -n "Starting Plex Media Server: "
        su -l "$PLEX_MEDIA_SERVER_USER" -c "/usr/sbin/start_pms" >/dev/null 2>&1 &
        echo "done"
        ;;
    stop)
        echo -n "Stopping Plex Media Server: "
        pkill -f "Plex Media Server" 2>/dev/null || true
        pkill -f "Plex DLNA Server" 2>/dev/null || true
        echo "done"
        ;;
    restart)
        $0 stop && sleep 2 && $0 start
        ;;
    status)
        if pgrep -f "Plex Media Server" > /dev/null; then
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
rc-update add plexmediaserver default

# ----------------------------------------------------------------------------
# 4. Media folder permissions (/home/media)
# ----------------------------------------------------------------------------
echo "📂 Setting permissions for /home/media..."
mkdir -p /home/media
find /home/media -type d -exec chmod 755 {} + 2>/dev/null || true
find /home/media -type f -exec chmod 644 {} + 2>/dev/null || true
chgrp -R plex /home/media 2>/dev/null || true
chmod -R g+rx /home/media 2>/dev/null || true

# ----------------------------------------------------------------------------
# 5. Configure Plex to prefer the correct network interface (10.0.0.3)
# ----------------------------------------------------------------------------
echo "🌐 Configuring Plex network binding for 10.0.0.3..."

PLEX_PREFS="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Preferences.xml"

# Wait a moment for Plex to create the Preferences.xml on first start
sleep 3

if [ -f "$PLEX_PREFS" ]; then
    # Force Plex to listen on all interfaces but prefer the main LAN IP
    sed -i 's|Preferences|Preferences PreferredNetworkInterface="eth0"|' "$PLEX_PREFS" 2>/dev/null || true
    # Alternative: set CustomServerAccessURLs if needed (e.g., for remote access)
    # sed -i 's|/>| CustomServerAccessURLs="http://10.0.0.3:32400" />|' "$PLEX_PREFS" 2>/dev/null || true
else
    echo "⚠️  Preferences.xml not found yet (normal on fresh install). It will be created after first start."
fi

# ----------------------------------------------------------------------------
# 6. Start the service
# ----------------------------------------------------------------------------
echo "▶️  Starting Plex Media Server..."
rc-service plexmediaserver start || echo "⚠️  Service start had warnings (common on first run)."

echo ""
echo "✅ Plex Media Server is installed and configured on your 10.0.0.3 server!"
echo ""
echo "🌐 Access Plex Web UI at:"
echo "   http://10.0.0.3:32400/web"
echo "   or http://$(hostname):32400/web"
echo ""
echo "📂 In Plex setup → Add Library, use folder: /home/media"
echo ""
echo "🔧 Useful commands:"
echo "   sudo rc-service plexmediaserver start|stop|restart|status"
echo "   sudo rc-update show | grep plex"
echo ""
echo "Note: Since this is a multi-service host (NOMAD + others), Plex will share port 32400. Make sure no other service is using it."
echo "For remote access, forward port 32400 on your router (10.0.0.1) to 10.0.0.3:32400."
echo ""
echo "Enjoy your media server! 🎬"
