# Determine the user's configured login shell
user_shell="${SHELL##*/}"

case "$user_shell" in
    zsh)
        rc_file="$HOME/.zshrc"
        backup_file="$HOME/.zshrc-bak"
        ;;
    bash)
        rc_file="$HOME/.bashrc"
        backup_file="$HOME/.bashrc-bak"
        ;;
    *)
        printf 'Unsupported shell: %s\n' "$user_shell" >&2
        exit 1
        ;;
esac

# Ensure the configuration file exists
if [ ! -f "$rc_file" ]; then
    printf 'Configuration file not found: %s\n' "$rc_file" >&2
    exit 1
fi

# Ask before overwriting an existing backup
if [ -e "$backup_file" ]; then
    printf 'Backup already exists: %s\n' "$backup_file"
    printf 'Overwrite it? [Y/n] '
    read -r answer

    case "$answer" in
        [nN]|[nN][oO])
            printf 'Backup not overwritten.\n'
            exit 0
            ;;
    esac
fi

cp -- "$rc_file" "$backup_file" &&
    printf 'Backup created: %s\n' "$backup_file"
