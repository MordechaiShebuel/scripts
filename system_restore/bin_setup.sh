#!/bin/bash

USERNAME="${1:-$USER}"

echo "Copying setting files to root of $USERNAME."
yes | /bin/cp -rf ../support/* /home/$USERNAME/
