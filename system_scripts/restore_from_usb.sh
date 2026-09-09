#!/bin/bash

# Steam and Browser Incremental Restore Script for Linux
# Usage: ./restore_from_usb.sh /path/to/usb [username] [hostname]

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

BACKUP_ROOT="$USB_PATH/$HOSTNAME/$USERNAME"
USER_HOME="/home/$USERNAME"

# Validate backup root exists
if [ ! -d "$BACKUP_ROOT" ]; then
    echo -e "${RED}Error: No backups found at $BACKUP_ROOT${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}Restore utility${NC}"
echo -e "${BLUE}Hostname: $HOSTNAME${NC}"
echo -e "${BLUE}User: $USERNAME${NC}"
echo -e "${BLUE}Backup root: $BACKUP_ROOT${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo

# List available backups (excluding 'latest' symlink)
BACKUPS=($(ls -1d "$BACKUP_ROOT"/*/ 2>/dev/null | grep -v '/latest$' | sed 's|.*/||; s|/$||' | sort))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo -e "${RED}Error: No backups found${NC}"
    exit 1
fi

echo -e "${BLUE}Available backups:${NC}"
for i in "${!BACKUPS[@]}"; do
    backup="${BACKUPS[$i]}"
    backup_date=$(echo "$backup" | sed 's/_/ /')
    size=$(du -sh "$BACKUP_ROOT/$backup" 2>/dev/null | cut -f1)
    printf "  [%d] %s (size: %s)\n" $((i+1)) "$backup_date" "$size"
done
echo

read -p "Restore from backup number (enter range like '1' or '1-3' for cumulative): " selection

# Parse selection
if [[ $selection =~ ^([0-9]+)(-([0-9]+))?$ ]]; then
    start_idx=$((${BASH_REMATCH[1]} - 1))
    end_idx=$((${BASH_REMATCH[3]:-${BASH_REMATCH[1]}} - 1))
else
    echo -e "${RED}Invalid selection${NC}"
    exit 1
fi

# Validate indices
if [ $start_idx -lt 0 ] || [ $start_idx -ge ${#BACKUPS[@]} ] ||
   [ $end_idx -lt 0 ] || [ $end_idx -ge ${#BACKUPS[@]} ] ||
   [ $start_idx -gt $end_idx ]; then
    echo -e "${RED}Invalid backup selection${NC}"
    exit 1
fi

# Prepare list of backups to restore (in order)
RESTORE_BACKUPS=()
for ((i=start_idx; i<=end_idx; i++)); do
    RESTORE_BACKUPS+=("${BACKUPS[$i]}")
done

echo -e "${BLUE}Selected backups for restore:${NC}"
for backup in "${RESTORE_BACKUPS[@]}"; do
    echo "  → $backup"
done
echo

echo -e "${YELLOW}WARNING: This will overwrite existing data${NC}"
echo -e "${RED}Target location: $USER_HOME${NC}"
read -p "Continue with restore? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo
echo -e "${YELLOW}Starting restore...${NC}"
echo

# Function to restore directory from a single backup
restore_dir() {
    local backup_source="$1"
    local restore_target="$2"
    local backup_name="$3"

    if [ ! -d "$backup_source" ]; then
        return
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$restore_target")"

    # Use rsync to restore (allows accumulative restores)
    if rsync -av --delete "$backup_source/" "$restore_target/" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $backup_name restored${NC}"
    else
        echo -e "${RED}✗ Failed to restore $backup_name${NC}"
        return 1
    fi
}

# Track failures
FAILED=0

# Restore from each backup in chronological order
for backup_timestamp in "${RESTORE_BACKUPS[@]}"; do
    backup_path="$BACKUP_ROOT/$backup_timestamp"

    echo -e "${BLUE}Restoring from: $backup_timestamp${NC}"

    # Personal Files
    restore_dir "$backup_path/Documents" "$USER_HOME/Documents" "documents" || FAILED=1

    # Restore Steam
    restore_dir "$backup_path/steam" "$USER_HOME/.steam" "steam" || FAILED=1

    # Restore Zen Browser
    restore_dir "$backup_path/zen_config" "$USER_HOME/.config/zen" "zen" || FAILED=1

    # Restore Brave Browser
    restore_dir "$backup_path/brave_config" "$USER_HOME/.config/BraveSoftware" "brave" || FAILED=1

    # Restore Falkon Browser
    restore_dir "$backup_path/falkon_config" "$USER_HOME/.config/falkon" "falkon" || FAILED=1

    echo
done

echo -e "${BLUE}═══════════════════════════════════════${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}Restore complete!${NC}"
else
    echo -e "${RED}Restore completed with errors!${NC}"
    exit 1
fi
