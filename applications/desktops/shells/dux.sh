#!/bin/bash
#
sudo xbps-install -Syu

pkgs=(
    dfiles
    dux-gop
    dux-search
    dux-calendar
    dux-shell
    matugen
)

sudo xbps-install -Sy "${pkgs[@]}"

# Greeter:
# echo 'repository=https://void.duxlabs.dev/dux-repo/current' | sudo tee /etc/xbps.d/dux.conf
# sudo xbps-install -S dux-greeter
# sudo xbps-install -S dux-greeter-git   # master snapshots; Conflicts with stable
# Cannot install due to missing libraries:
# MISSING: acl-progs>=0
# MISSING: pam_rundir>=0
