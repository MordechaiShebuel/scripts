This conversation was generated with Duck.ai (https://duck.ai) using Anthropic's Claude Haiku 4.5 Model. AI chats may display inaccurate or offensive information (see https://duckduckgo.com/duckai/privacy-terms for more info).

====================

User prompt 1 of 2 - 9/7/2026, 11:12:13 PM:
Need a script to back up steam directory (linux) browser info (Zen, Brave, Falkon) to a USB drive. (Path to USB can be primary argument user secondary argument)

Don't care about KDE settings, or other things.

Then make a restore script that copies it from the backup drive to the local user drive

Claude Haiku 4.5:
I'll create both a backup and restore script for you. These will handle Steam and browser data on Linux.

## Backup Script

Save this as `backup_to_usb.sh`:

```bash
#!/bin/bash

# Steam and Browser Backup Script for Linux
# Usage: ./backup_to_usb.sh /path/to/usb [username]

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Arguments
USB_PATH="${1:?Error: USB path required as first argument}"
USERNAME="${2:-$USER}"

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
BACKUP_DIR="$USB_PATH/steam_browser_backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${YELLOW}Starting backup to: $BACKUP_DIR${NC}"
mkdir -p "$BACKUP_DIR"

# Function to backup directory
backup_dir() {
    local source="$1"
    local backup_name="$2"
    
    if [ -d "$source" ]; then
        echo -e "${YELLOW}Backing up: $backup_name${NC}"
        cp -r "$source" "$BACKUP_DIR/$backup_name"
        echo -e "${GREEN}✓ $backup_name backed up${NC}"
    else
        echo -e "${YELLOW}⊘ $backup_name not found at $source (skipping)${NC}"
    fi
}

# Backup Steam
backup_dir "$USER_HOME/.steam" "steam"
backup_dir "$USER_HOME/.steamapps" "steamapps"
backup_dir "$USER_HOME/.local/share/Steam" "Steam_local_share"

# Backup Zen Browser
backup_dir "$USER_HOME/.config/zen" "zen_config"
backup_dir "$USER_HOME/.local/share/zen" "zen_data"

# Backup Brave Browser
backup_dir "$USER_HOME/.config/BraveSoftware" "brave_config"
backup_dir "$USER_HOME/.local/share/BraveSoftware" "brave_data"

# Backup Falkon Browser
backup_dir "$USER_HOME/.config/falkon" "falkon_config"
backup_dir "$USER_HOME/.local/share/falkon" "falkon_data"

echo -e "${GREEN}Backup complete!${NC}"
echo -e "${GREEN}Location: $BACKUP_DIR${NC}"
du -sh "$BACKUP_DIR"
```

## Restore Script

Save this as `restore_from_usb.sh`:

```bash
#!/bin/bash

# Steam and Browser Restore Script for Linux
# Usage: ./restore_from_usb.sh /path/to/backup [username]

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Arguments
BACKUP_PATH="${1:?Error: Backup path required as first argument}"
USERNAME="${2:-$USER}"

# Validate backup path
if [ ! -d "$BACKUP_PATH" ]; then
    echo -e "${RED}Error: Backup path '$BACKUP_PATH' does not exist${NC}"
    exit 1
fi

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo -e "${RED}Error: User '$USERNAME' does not exist${NC}"
    exit 1
fi

USER_HOME="/home/$USERNAME"

echo -e "${YELLOW}WARNING: This will overwrite existing data${NC}"
read -p "Continue with restore? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo -e "${YELLOW}Starting restore for user: $USERNAME${NC}"

# Function to restore directory
restore_dir() {
    local backup_source="$1"
    local restore_target="$2"
    local backup_name="$3"
    
    if [ -d "$backup_source" ]; then
        echo -e "${YELLOW}Restoring: $backup_name${NC}"
        
        # Create parent directory if needed
        mkdir -p "$(dirname "$restore_target")"
        
        # Remove existing if present
        if [ -d "$restore_target" ]; then
            rm -rf "$restore_target"
        fi
        
        cp -r "$backup_source" "$restore_target"
        echo -e "${GREEN}✓ $backup_name restored${NC}"
    else
        echo -e "${YELLOW}⊘ $backup_name not found in backup (skipping)${NC}"
    fi
}

# Restore Steam
restore_dir "$BACKUP_PATH/steam" "$USER_HOME/.steam" "Steam"
restore_dir "$BACKUP_PATH/steamapps" "$USER_HOME/.steamapps" "SteamApps"
restore_dir "$BACKUP_PATH/Steam_local_share" "$USER_HOME/.local/share/Steam" "Steam local share"

# Restore Zen Browser
restore_dir "$BACKUP_PATH/zen_config" "$USER_HOME/.config/zen" "Zen config"
restore_dir "$BACKUP_PATH/zen_data" "$USER_HOME/.local/share/zen" "Zen data"

# Restore Brave Browser
restore_dir "$BACKUP_PATH/brave_config" "$USER_HOME/.config/BraveSoftware" "Brave config"
restore_dir "$BACKUP_PATH/brave_data" "$USER_HOME/.local/share/BraveSoftware" "Brave data"

# Restore Falkon Browser
restore_dir "$BACKUP_PATH/falkon_config" "$USER_HOME/.config/falkon" "Falkon config"
restore_dir "$BACKUP_PATH/falkon_data" "$USER_HOME/.local/share/falkon" "Falkon data"

echo -e "${GREEN}Restore complete!${NC}"
```

---

## Usage

**Make scripts executable:**
```bash
chmod +x backup_to_usb.sh restore_from_usb.sh
```

**Backup (to USB):**
```bash
# Primary user (current user)
./backup_to_usb.sh /mnt/usb

# Specific user
./backup_to_usb.sh /mnt/usb username
```

**Restore (from USB):**
```bash
# Primary user (current user)
./restore_from_usb.sh /mnt/usb/steam_browser_backup_20260907_143022

# Specific user
./restore_from_usb.sh /mnt/usb/steam_browser_backup_20260907_143022 username
```

---

## Key Features

- **Timestamped backups** — prevents overwriting previous backups
- **Error handling** — validates paths and user existence
- **Graceful skipping** — continues if directories don't exist
- **Selective restore** — asks for confirmation before overwriting
- **Color output** — visual feedback on progress
- **Size reporting** — shows backup size after completion
- **Covers all relevant directories** — Steam, Zen, Brave, and Falkon

The backup script creates a timestamped folder, so you can keep multiple backups. The restore script points to a specific backup directory, giving you control over which backup to restore from.

--------------------

User prompt 2 of 2 - 9/7/2026, 11:18:01 PM:
Add $HostName and $User to the backup folder name. $hostname can be argument 3, And default to the environ variable.

Claude Haiku 4.5:
I'll update both scripts to include hostname and user in the backup folder name.

## Updated Backup Script

Save this as `backup_to_usb.sh`:

```bash
#!/bin/bash

# Steam and Browser Backup Script for Linux
# Usage: ./backup_to_usb.sh /path/to/usb [username] [hostname]

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Arguments
USB_PATH="${1:?Error: USB path required as first argument}"
USERNAME="${2:-$USER}"
HOSTNAME="${3:-$HOSTNAME}"

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
BACKUP_DIR="$USB_PATH/backup_${HOSTNAME}_${USERNAME}_$(date +%Y%m%d_%H%M%S)"

echo -e "${YELLOW}Starting backup to: $BACKUP_DIR${NC}"
mkdir -p "$BACKUP_DIR"

# Function to backup directory
backup_dir() {
    local source="$1"
    local backup_name="$2"
    
    if [ -d "$source" ]; then
        echo -e "${YELLOW}Backing up: $backup_name${NC}"
        cp -r "$source" "$BACKUP_DIR/$backup_name"
        echo -e "${GREEN}✓ $backup_name backed up${NC}"
    else
        echo -e "${YELLOW}⊘ $backup_name not found at $source (skipping)${NC}"
    fi
}

# Backup Steam
backup_dir "$USER_HOME/.steam" "steam"
backup_dir "$USER_HOME/.steamapps" "steamapps"
backup_dir "$USER_HOME/.local/share/Steam" "Steam_local_share"

# Backup Zen Browser
backup_dir "$USER_HOME/.config/zen" "zen_config"
backup_dir "$USER_HOME/.local/share/zen" "zen_data"

# Backup Brave Browser
backup_dir "$USER_HOME/.config/BraveSoftware" "brave_config"
backup_dir "$USER_HOME/.local/share/BraveSoftware" "brave_data"

# Backup Falkon Browser
backup_dir "$USER_HOME/.config/falkon" "falkon_config"
backup_dir "$USER_HOME/.local/share/falkon" "falkon_data"

echo -e "${GREEN}Backup complete!${NC}"
echo -e "${GREEN}Location: $BACKUP_DIR${NC}"
du -sh "$BACKUP_DIR"
```

## Updated Restore Script

Save this as `restore_from_usb.sh`:

```bash
#!/bin/bash

# Steam and Browser Restore Script for Linux
# Usage: ./restore_from_usb.sh /path/to/backup [username] [hostname]

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Arguments
BACKUP_PATH="${1:?Error: Backup path required as first argument}"
USERNAME="${2:-$USER}"
HOSTNAME="${3:-$HOSTNAME}"

# Validate backup path
if [ ! -d "$BACKUP_PATH" ]; then
    echo -e "${RED}Error: Backup path '$BACKUP_PATH' does not exist${NC}"
    exit 1
fi

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo -e "${RED}Error: User '$USERNAME' does not exist${NC}"
    exit 1
fi

USER_HOME="/home/$USERNAME"

echo -e "${YELLOW}Restoring from: $BACKUP_PATH${NC}"
echo -e "${YELLOW}Target user: $USERNAME${NC}"
echo -e "${YELLOW}Target hostname: $HOSTNAME${NC}"
echo -e "${YELLOW}WARNING: This will overwrite existing data${NC}"
read -p "Continue with restore? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo -e "${YELLOW}Starting restore for user: $USERNAME on $HOSTNAME${NC}"

# Function to restore directory
restore_dir() {
    local backup_source="$1"
    local restore_target="$2"
    local backup_name="$3"
    
    if [ -d "$backup_source" ]; then
        echo -e "${YELLOW}Restoring: $backup_name${NC}"
        
        # Create parent directory if needed
        mkdir -p "$(dirname "$restore_target")"
        
        # Remove existing if present
        if [ -d "$restore_target" ]; then
            rm -rf "$restore_target"
        fi
        
        cp -r "$backup_source" "$restore_target"
        echo -e "${GREEN}✓ $backup_name restored${NC}"
    else
        echo -e "${YELLOW}⊘ $backup_name not found in backup (skipping)${NC}"
    fi
}

# Restore Steam
restore_dir "$BACKUP_PATH/steam" "$USER_HOME/.steam" "Steam"
restore_dir "$BACKUP_PATH/steamapps" "$USER_HOME/.steamapps" "SteamApps"
restore_dir "$BACKUP_PATH/Steam_local_share" "$USER_HOME/.local/share/Steam" "Steam local share"

# Restore Zen Browser
restore_dir "$BACKUP_PATH/zen_config" "$USER_HOME/.config/zen" "Zen config"
restore_dir "$BACKUP_PATH/zen_data" "$USER_HOME/.local/share/zen" "Zen data"

# Restore Brave Browser
restore_dir "$BACKUP_PATH/brave_config" "$USER_HOME/.config/BraveSoftware" "Brave config"
restore_dir "$BACKUP_PATH/brave_data" "$USER_HOME/.local/share/BraveSoftware" "Brave data"

# Restore Falkon Browser
restore_dir "$BACKUP_PATH/falkon_config" "$USER_HOME/.config/falkon" "Falkon config"
restore_dir "$BACKUP_PATH/falkon_data" "$USER_HOME/.local/share/falkon" "Falkon data"

echo -e "${GREEN}Restore complete!${NC}"
```

---

## Usage

**Backup examples:**
```bash
# Uses current user and system hostname
./backup_to_usb.sh /mnt/usb

# Specify user (uses system hostname)
./backup_to_usb.sh /mnt/usb alice

# Specify user and hostname
./backup_to_usb.sh /mnt/usb alice laptop-01
```

**Backup folder name format:** `backup_${hostname}_${username}_${timestamp}`

Example: `backup_laptop-01_alice_20260907_143022`

**Restore examples:**
```bash
# Restore to current user and system hostname
./restore_from_usb.sh /mnt/usb/backup_laptop-01_alice_20260907_143022

# Restore to different user (uses system hostname)
./restore_from_usb.sh /mnt/usb/backup_laptop-01_alice_20260907_143022 bob

# Restore to different user and hostname
./restore_from_usb.sh /mnt/usb/backup_laptop-01_alice_20260907_143022 bob desktop-02
```

The restore script now also displays the target hostname and user before asking for confirmation.
