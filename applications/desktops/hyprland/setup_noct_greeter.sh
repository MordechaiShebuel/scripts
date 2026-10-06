#!/bin/bash

set -e  # Exit on error

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo "=== Setting up greeter ==="

# Configure greetd
echo "[*] Configuring greetd..."

echo ""
echo "Available greeters:"
echo "1) noctalia-greeter (Noctalia-themed)"
echo "2) tuigreet (TUI, lightweight)"
echo "3) gtkgreet (GTK-based, traditional)"
echo "4) greetd-wlgreet (Wayland-native)"
echo "5) agreety (Simple TUI)"
echo "6) dlm (Dmenu-based)"
echo ""

read -p "Select greeter (1-6): " greeter_choice

case $greeter_choice in
    1)
        greeter_cmd="cage -s -- noctalia-greeter-session"
        greeter_pkg="noctalia-greeter"
        ;;
    2)
        greeter_cmd="tuigreet --cmd dbus-run-session start-hyprland"
        greeter_pkg="tuigreet"
        ;;
    3)
        greeter_cmd="cage -s -- gtkgreet"
        greeter_pkg="gtkgreet"
        ;;
    4)
        greeter_cmd="cage -s -- greetd-wlgreet"
        greeter_pkg="greetd-wlgreet"
        ;;
    5)
        greeter_cmd="agreety --cmd dbus-run-session start-hyprland"
        greeter_pkg="agreety"
        ;;
    6)
        greeter_cmd="dlm"
        greeter_pkg="dlm"
        ;;
    *)
        echo "Invalid selection"
        exit 1
        ;;
esac
echo "[*] Installing greetd and $greeter_pkg..."
xbps-install -Sy greetd $greeter_pkg

echo "Setup greeter user"
if ! id greeter >/dev/null 2>&1; then
    useradd -r -s /bin/nologin -d /var/lib/greeter -m greeter
fi
usermod -aG video greeter

# Verify greeter user
echo "[*] Checking greeter user..."
if id greeter &>/dev/null; then
    echo "[+] greeter user exists"
else
    echo "[-] greeter user not found. Please create it manually."
    exit 1
fi

# Disable SDDM if running
# if [[ -L /var/service/sddm ]]; then
#     echo "[*] Disabling SDDM..."
#     rm /var/service/sddm
# fi

cat > /etc/greetd/config.toml << EOF
[default_session]
command = "$greeter_cmd"
user = "greeter"
vt = 8

[general]
log_level = "debug"
EOF

# Enable greetd
echo "[*] Enabling greetd service..."
if [[ ! -L /var/service/greetd ]]; then
    ln -s /etc/sv/greetd /var/service/
else
    echo "[!] greetd service already enabled"
fi

echo ""
echo "=== Setup complete ==="
echo "Reboot to apply changes: sudo reboot"
