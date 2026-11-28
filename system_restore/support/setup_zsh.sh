#!/bin/bash
#
USERNAME="${1:-$USER}"

if [[ -d /home/$USERNAME/.oh-my-zsh ]]; then
    # do nothing
    echo "Oh My ZSH already installed\!"
else
    echo "Installing OMZ\!"
    if curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" | sh; then
        echo "OMZ Install complete."
    else
        echo "OMZ Install fails.">&2
        exit 1
    fi
fi

sudo chsh -s "$(command -v zsh)" "$USERNAME"

if getent passwd "$USERNAME" | grep -qE ':/bin/zsh$'; then # Even though this works, it displays it isn't set to ZSH
    echo "Your login shell is set to zsh."
else
    echo "Your login shell is not set to zsh."
fi

desired="/usr/share/zsh/plugins/zsh-syntax-highlighting"
dest="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$desired" ]; then
        echo "Correct symlink already present"
    else
        echo "Symlink points to a different target ($(readlink "$dest")), updating..."
        ln -sf "$desired" "$dest"
    fi
elif [ -e "$dest" ]; then
    echo "A file or directory exists at $dest; not creating symlink"
else
    ln -s "$desired" "$dest"
    echo "Symlink created"
fi
