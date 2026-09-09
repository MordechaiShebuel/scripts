#!/bin/bash

USERNAME="${1:-$USER}"
# Setup client printer:
sudo lpadmin -p "HP_LaserJet_Pro_M148f-M149f" \
    -v "ipp://server.lan:631/printers/HP_LaserJet_Pro_M148f-M149f" \
    -m everywhere -E

# Setup client scanner access through SANE:
echo server.lan | sudo tee /etc/sane.d/net.conf

# Setup file-sharing client access:
sudo ./setup_file_sharing.sh $USERNAME
