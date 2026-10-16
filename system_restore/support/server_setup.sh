#!/bin/bash
# Setup print server:
sudo ./print_server_setup.sh

# Setup file server:
sudo ./setup_server_file_sharing.sh

# Setup SANE server:
echo 10.0.0.0/24 | sudo tee /etc/sane.d/saned.conf
