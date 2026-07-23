#!/usr/bin/env bash
BACKUP_DIR="/home/backup/timeshift"

#
# Goals:
# 1. Install timeshift
../system_scripts/./install.sh timeshift

# before continuing, need to make sure timeshift is installed
if ! command -v timeshift &> /dev/null; then
    echo "timeshift could not be found, exiting"
    exit 1
fi

# 2. setup backup drive location
sudo mkdir -p "$BACKUP_DIR"

# 3. Initialize timeshift
sudo timeshift --create --comments "initial" --tags D

# 4. setup schedule
# This command does not work
# sudo timeshift --schedule

# 5. save package lists
sudo pacman -Qqe > "$BACKUP_DIR"/pkglist-explicit.txt
sudo pacman -Qm > "$BACKUP_DIR"/pkglist-foreign.txt
