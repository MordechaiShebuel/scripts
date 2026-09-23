#!/bin/bash

if ! command -v ente-auth >/dev/null 2>&1; then
    # install ente-auth
    wget https://github.com/ente/ente/releases/download/auth-v4.4.25/ente-auth-v4.4.25-x86_64.AppImage &&
        sudo mkdir -p /opt/bin &&
        sudo cp ente-auth-* /opt/bin &&
        sudo chmod +x /opt/bin/ente-auth-v4.4.25-x86_64.AppImage &&
        sudo ln -s /opt/bin/ente-auth-v4.4.25-x86_64.AppImage /usr/bin/ente-auth &&
        tee ~/.local/share/applications/ente-auth.desktop <<EOF
[Desktop Entry]
Name=Ente Auth
Exec=ente-auth
Type=Application
Icon=/opt/bin/ente-auth-v4.4.25-x86_64.AppImage
Terminal=false
Categories=Utility;Security;
EOF
    echo "Ente-Auth installed"
else
    echo "Ente-Auth already installed."
fi
