#!/bin/bash
# configure-cups-client.sh
# Configures this machine as a CUPS client pointing to polite-and-humble.lan:631

set -e

PRINT_SERVER="polite-and-humble.lan:631"
CUPSD_CONF="/etc/cups/cupsd.conf"
CLIENT_CONF="/etc/cups/client.conf"

echo "=== Configuring CUPS client for print server: $PRINT_SERVER ==="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (use sudo)"
   exit 1
fi

# Backup original configs
echo "[1/5] Backing up CUPS configurations..."
cp "$CUPSD_CONF" "$CUPSD_CONF.backup.$(date +%s)"
cp "$CLIENT_CONF" "$CLIENT_CONF.backup.$(date +%s)" 2>/dev/null || true

# Stop CUPS daemon
echo "[2/5] Stopping CUPS daemon..."
if command -v rc-service &> /dev/null; then
    rc-service cupsd stop || true
elif command -v systemctl &> /dev/null; then
    systemctl stop cups || true
else
    echo "Warning: Could not determine service manager (openRC/systemd)"
fi

# Configure cupsd.conf for client-only mode
echo "[3/5] Configuring cupsd.conf for client-only mode..."
cat > "$CUPSD_CONF" << 'EOF'
# Client-only CUPS configuration
# This machine acts as a CUPS client, not a server

LogLevel warn
MaxLogSize 0
Listen /run/cups/cups.sock
Listen localhost:631
Port 631

# Disable all remote access
<Location />
  Order allow,deny
  Allow localhost
  Allow 127.0.0.1
</Location>

<Location /admin>
  Order allow,deny
  Allow localhost
  Allow 127.0.0.1
</Location>

<Location /admin/conf>
  Order allow,deny
  Allow localhost
  Allow 127.0.0.1
</Location>
EOF

# Configure client.conf to point to print server
echo "[4/5] Configuring client.conf to point to $PRINT_SERVER..."
cat > "$CLIENT_CONF" << EOF
# CUPS client configuration
ServerName $PRINT_SERVER
EOF

# Set proper permissions
echo "[5/5] Setting permissions..."
chmod 640 "$CUPSD_CONF"
chmod 644 "$CLIENT_CONF"

echo ""
echo "=== Configuration Complete ==="
echo "Print server: $PRINT_SERVER"
echo ""
echo "To verify configuration, run:"
echo "  lpstat -h $PRINT_SERVER -p"
echo ""
echo "To test printing, run:"
echo "  lp -h $PRINT_SERVER -d <printer_name> <file>"
echo ""
