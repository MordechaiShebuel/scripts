#!/bin/sh
set -eu

SUBNET="10.0.0.0/24"
CUPSD_CONF="/etc/cups/cupsd.conf"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root: sudo $0"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "Installing CUPS and HPLIP..."
apt-get update
apt-get install -y cups hplip printer-driver-hpcups

echo "Starting CUPS..."
sv up cups

echo "Checking for the USB printer..."

if ! hp-probe -b usb 2>&1 |
       grep -qiE 'hp:/usb/HP_LaserJet_Pro_M148f-M149f'; then
    echo "Warning: the HP LaserJet Pro M148fdw was not detected."
    echo "Make sure it is powered on and connected by USB."
    exit 1
else
    echo "Printer detected."
fi

echo "Running HPLIP setup..."
hp-setup -i -a

PRINTER_NAME="$(
    lpstat -p 2>/dev/null |
    sed -n 's/^printer \([^ ]*\) .*/\1/p' |
    grep -iE 'M148|MFP|LaserJet|HP' |
    head -n 1 || true
)"

fi

if [ -z "$PRINTER_NAME" ]; then
    echo "Could not determine the printer queue created by hp-setup."
    echo "Run: lpstat -p"
    exit 1
fi

echo "Sharing printer queue: $PRINTER_NAME"
lpadmin -p "$PRINTER_NAME" -o printer-is-shared=true

# Remove this script's previous CUPS access block, if present.
sed -i \
    '/^# BEGIN 10.0.0.0\/24 printer sharing$/,/^# END 10.0.0.0\/24 printer sharing$/d' \
    "$CUPSD_CONF"

cat >> "$CUPSD_CONF" <<EOF

# BEGIN 10.0.0.0/24 printer sharing
<Location />
    Allow 10.0.0.0/24
</Location>

<Location /printers>
    Allow 10.0.0.0/24
</Location>

<Location /admin>
    Allow 10.0.0.0/24
</Location>
# END 10.0.0.0/24 printer sharing
EOF

# Make CUPS listen on the network.
if ! grep -qE '^[[:space:]]*(Port 631|Listen 0\.0\.0\.0:631)' "$CUPSD_CONF"; then
    cat >> "$CUPSD_CONF" <<'EOF'

# Listen for LAN clients
Port 631
EOF
fi

echo "Restarting CUPS..."
sv restart cups

echo
echo "Setup complete."
echo "Printer queue: $PRINTER_NAME"
echo "Clients on $SUBNET can use:"
echo "  ipp://$(hostname -f):631/printers/$PRINTER_NAME"
echo
echo "Verify with:"
echo "  lpstat -p -d"
echo "  lpstat -v $PRINTER_NAME"
echo "  sv status cups"
