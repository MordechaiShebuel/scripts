#!/bin/bash
# Setup print server:
sudo ./server_setup_lp_devuan.sh

# Setup file server:
sudo ./server_file_sharing_devuan.sh

# Setup SANE server:
echo 10.0.0.0/24 | sudo tee /etc/sane.d/saned.conf

# For Raku:
# RakuOS firewall was blocking TCP disallowing server / scanner control
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="10.0.0.0/24" port port="6566" protocol="tcp" accept' --permanent
sudo firewall-cmd --reload
