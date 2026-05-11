#!/usr/bin/env bash
# Goals:
# 1. Install timeshift
./install.sh timeshift

# 2. setup backup drive location
sudo mkdir -p /mnt/backup

# 3. Initialize timeshift
sudo timeshift --create --comments "initial" --tags D

# 4. setup schedule
sudo timeshift --schedule

# 5. save package lists
sudo pacman -Qqe > /mnt/backup/pkglist-explicit.txt
sudo pacman -Qm > /mnt/backup/pkglist-foreign.txt
