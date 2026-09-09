#!/bin/bash

# Steam and Browser Incremental Backup Script for Linux
# Usage: ./backup_to_usb.sh /path/to/usb [username] [hostname]

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Arguments
USB_PATH="${1:?Error: USB path required as first argument}"
USERNAME="${2:-$USER}"
HOSTNAME="${3:-$(hostname)}"

# Validate USB path
if [ ! -d "$USB_PATH" ]; then
    echo -e "${RED}Error: USB path '$USB_PATH' does not exist${NC}"
    exit 1
fi

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo -e "${RED}Error: User '$USERNAME' does not exist${NC}"
    exit 1
fi

USER_HOME="/home/$USERNAME"
BACKUP_ROOT="$USB_PATH/$HOSTNAME/$USERNAME"
CURRENT_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$CURRENT_TIMESTAMP"
LATEST_LINK="$BACKUP_ROOT/latest"

# Create backup directory structure
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}Starting incremental backup${NC}"
echo -e "${BLUE}Hostname: $HOSTNAME${NC}"
echo -e "${BLUE}User: $USERNAME${NC}"
echo -e "${BLUE}Root: $BACKUP_ROOT${NC}"
echo -e "${BLUE}Backup: $BACKUP_DIR${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

# Function to perform incremental backup
# Uses rsync to only copy changed files
backup_dir() {
    local source="$1"
    local backup_name="$2"
    local target="$BACKUP_DIR/$backup_name"

    if [ ! -d "$source" ]; then
        echo -e "${YELLOW}⊘ $backup_name not found at $source (skipping)${NC}"
        return
    fi

    echo -e "${YELLOW}Backing up: $backup_name${NC}"

    # Use rsync for incremental backup with hard links from previous backup
    local rsync_opts=("-av" "--delete" "--stats")

    # If a previous backup exists, link unchanged files
    if [ -L "$LATEST_LINK" ] && [ -d "$LATEST_LINK/$backup_name" ]; then
        echo -e "${BLUE}  (using previous backup as reference)${NC}"
        rsync_opts+=("--link-dest=$LATEST_LINK/$backup_name")
    fi

    mkdir -p "$target"

    # Perform the rsync - use array expansion
    rsync_output=$(rsync "${rsync_opts[@]}" "$source/" "$target/" 2>&1)
    rsync_exit=$?

    if [ $rsync_exit -eq 0 ]; then
        echo -e "${GREEN}✓ $backup_name backed up${NC}"
    elif [ $rsync_exit -eq 23 ]; then
        echo -e "${YELLOW}⚠ $backup_name backed up (some files skipped)${NC}"
        echo "  Details: $rsync_output" | grep -i "error\|permission" || true
    elif [ $rsync_exit -eq 24 ]; then
        echo -e "${YELLOW}⚠ $backup_name backed up (no new changes)${NC}"
    else
        echo -e "${RED}✗ Failed to backup $backup_name${NC}"
        echo "  Error: $rsync_output"
        return 1
    fi

}


# Track if any backup failed
FAILED=0

# Personal Files
backup_dir "$USER_HOME/Documents" "documents" || FAILED=1

# Backup Steam
backup_dir "$USER_HOME/.steam" "steam" || FAILED=1
# This is too slow with a decent amount of games
# backup_dir "$USER_HOME/.local/share/Steam" "steam_apps" || FAILED=1

# Backup Zen Browser
backup_dir "$USER_HOME/.zen" "zen" || FAILED=1

# Backup Brave Browser
backup_dir "$USER_HOME/.config/BraveSoftware" "brave" || FAILED=1

# Backup Falkon Browser
backup_dir "$USER_HOME/.config/falkon" "falkon" || FAILED=1

# Update latest symlink
rm -f "$LATEST_LINK"
ln -s "$BACKUP_DIR" "$LATEST_LINK"

echo -e "${BLUE}═══════════════════════════════════════${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}Backup complete!${NC}"
    echo -e "${GREEN}Location: $BACKUP_DIR${NC}"
    echo -e "${BLUE}Total size:${NC}"
    du -sh "$BACKUP_DIR"
    echo
    echo -e "${BLUE}Backup history:${NC}"
    ls -1d "$BACKUP_ROOT"/*/ 2>/dev/null | sed 's|.*/||' | tail -5 || echo "  (no previous backups)"
else
    echo -e "${RED}Backup completed with errors!${NC}"
    exit 1
fi
