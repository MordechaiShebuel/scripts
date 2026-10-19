#!/bin/bash

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <new_username> <existing_username>"
    exit 1
fi

NEW_USER="$1"
EXISTING_USER="$2"

# Check if the existing user exists
if ! id "$EXISTING_USER" &>/dev/null; then
    echo "Error: User '$EXISTING_USER' does not exist."
    exit 1
fi

# Check if the new user already exists
if id "$NEW_USER" &>/dev/null; then
    echo "Error: User '$NEW_USER' already exists."
    exit 1
fi

# Create the new user
echo "Creating user '$NEW_USER'..."
sudo useradd -m -s /bin/bash "$NEW_USER"

if [ $? -eq 0 ]; then
    echo "User '$NEW_USER' created successfully."
else
    echo "Error: Failed to create user '$NEW_USER'."
    exit 1
fi

# --- Robust group copying ---
# Get the primary group name
PRIMARY_GROUP=$(id -gn "$EXISTING_USER")

# Build a comma-separated list of SUPPLEMENTARY groups (by name, excluding primary)
# Get the primary group GID
PRIMARY_GID=$(id -g "$EXISTING_USER")

# Get all group names for the existing user
ALL_GROUPS=$(id -Gn "$EXISTING_USER" | tr ' ' '\n')

echo "DEBUG: PRIMARY_GID = '$PRIMARY_GID'"
echo "DEBUG: ALL_GROUPS:"
echo "$ALL_GROUPS"

# Add each group to the new user, skipping the primary group
for group in $ALL_GROUPS; do
    if [ "$group" != "$EXISTING_USER" ]; then
        echo "Adding group: $group"
        sudo usermod -a -G "$group" "$NEW_USER"
    else
        echo "Skipping primary group: $group"
    fi
done

echo "Groups added successfully."

# Prompt for the new user's password
echo "Please enter a password for '$NEW_USER':"
sudo passwd "$NEW_USER"

if [ $? -eq 0 ]; then
    echo "Password set successfully for '$NEW_USER'."
else
    echo "Error: Failed to set password for '$NEW_USER'."
    exit 1
fi

# Ask if user wants to add new user to sudoers
read -p "Do you want to add new user to SUDOERS? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    echo "Adding $NEW_USER to sudoers..."
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/$NEW_USER > /dev/null
    sudo chmod 0440 /etc/sudoers.d/$NEW_USER
    echo "$NEW_USER added to sudoers successfully."
else
    echo "Skipping sudoers configuration."
fi

echo "User setup complete!"
