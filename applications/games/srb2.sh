#!/usr/bin/env bash

set -Eeuo pipefail

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

# Configuration
SRC_DIR="$HOME/src"
SRB2_DIR="$SRC_DIR/SRB2"
ASSETS_DIR="$SRC_DIR/srb2assets-public"
ASSETS_DEST="$HOME/.srb2"
INSTALL_PATH="/usr/local/games/srb2"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/srb2.desktop"

failed=()

log() {
    local level="$1"
    shift

    case "$level" in
        INFO)
            printf "%b[INFO]%b %s\n" "$BLUE" "$NC" "$*"
            ;;
        OK)
            printf "%b[ OK ]%b %s\n" "$GREEN" "$NC" "$*"
            ;;
        WARN)
            printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$*"
            ;;
        ERROR)
            printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$*" >&2
            ;;
    esac
}

on_error() {
    local exit_code=$?
    log ERROR "Command failed on line $LINENO: $BASH_COMMAND"
    log ERROR "Exit code: $exit_code"
    exit "$exit_code"
}

trap on_error ERR

log INFO "Starting Sonic Robo Blast 2 setup."

# 1. Check required commands
log INFO "Checking required commands."

for command in git make sudo; do
    if ! command -v "$command" >/dev/null 2>&1; then
        log ERROR "Required command not found: $command"
        exit 1
    fi
done

if ! command -v nproc >/dev/null 2>&1; then
    log WARN "nproc was not found; using a single build job."
    BUILD_JOBS=1
else
    BUILD_JOBS="$(nproc)"
fi

log OK "Required commands are available."

# 2. Define required packages
log INFO "Preparing package list."

reqs=(
    git
    base-devel
    cmake
    libcurl-devel
    miniupnpc-devel
    libopenmpt-devel
    libgme-devel
    SDL2-devel
    SDL2_image
    SDL2_image-devel
    SDL2_mixer
    SDL2_mixer-devel
    SDL2_net
    SDL2_net-devel
    SDL2_ttf
    SDL2_ttf-devel
    libpng
    libpng-devel
    zlib
    zlib-devel
)

# 3. Install requirements
log INFO "Installing packages required to build SRB2."

sudo -v

for pkg in "${reqs[@]}"; do
    log INFO "Installing package: $pkg"

    if sudo xbps-install -y "$pkg"; then
        log OK "Installed or already installed: $pkg"
    else
        log ERROR "Failed to install: $pkg"
        failed+=("$pkg")
    fi
done

if ((${#failed[@]} > 0)); then
    log ERROR "The following packages failed to install:"
    printf '  %s\n' "${failed[@]}"
    exit 1
fi

log OK "All required packages are installed."

# Install Git LFS if it is not already available
if ! command -v git-lfs >/dev/null 2>&1; then
    log INFO "Installing Git LFS."
    sudo xbps-install -y git-lfs
fi

log INFO "Initializing Git LFS."
git lfs install

# Clone or update the assets branch
ASSETS_BRANCH="SRB2_2.2"

if [[ -d "$ASSETS_DIR/.git" ]]; then
    log INFO "Updating assets repository."

    git -C "$ASSETS_DIR" fetch origin "$ASSETS_BRANCH"
    git -C "$ASSETS_DIR" checkout "$ASSETS_BRANCH"
    git -C "$ASSETS_DIR" pull --ff-only origin "$ASSETS_BRANCH"
else
    log INFO "Cloning assets branch: $ASSETS_BRANCH"

    git clone \
        --branch "$ASSETS_BRANCH" \
        --single-branch \
        https://git.do.srb2.org/STJr/srb2assets-public.git \
        "$ASSETS_DIR"
fi

log INFO "Downloading large assets through Git LFS."
git -C "$ASSETS_DIR" lfs pull

log OK "Assets repository is ready."

# 4. Create source directory
log INFO "Creating source directory: $SRC_DIR"
mkdir -p "$SRC_DIR"
log OK "Source directory is ready."

# 5. Clone or update SRB2
if [[ -d "$SRB2_DIR/.git" ]]; then
    log INFO "SRB2 repository already exists. Updating it."
    git -C "$SRB2_DIR" checkout master
    git -C "$SRB2_DIR" pull --ff-only
else
    if [[ -e "$SRB2_DIR" ]]; then
        log ERROR "$SRB2_DIR exists but is not a Git repository."
        exit 1
    fi

    log INFO "Cloning SRB2 source code."
    git clone https://git.do.srb2.org/STJr/SRB2.git "$SRB2_DIR"
fi

log OK "SRB2 source code is ready."

# 6. Build SRB2
log INFO "Cleaning previous build output."
make -C "$SRB2_DIR" clean

log INFO "Compiling SRB2 using $BUILD_JOBS parallel job(s)."
make -C "$SRB2_DIR" -j"$BUILD_JOBS"

log OK "SRB2 compiled successfully."

# 7. Clone or update assets
#
# Install Git LFS if it is not already available
if ! command -v git-lfs >/dev/null 2>&1; then
    log INFO "Installing Git LFS."
    sudo xbps-install -y git-lfs
fi

log INFO "Initializing Git LFS."
git lfs install

# Clone or update the assets branch
ASSETS_BRANCH="SRB2_2.2"

if [[ -d "$ASSETS_DIR/.git" ]]; then
    log INFO "Assets repository already exists. Updating it."

    git -C "$ASSETS_DIR" fetch origin "$ASSETS_BRANCH"
    git -C "$ASSETS_DIR" checkout "$ASSETS_BRANCH"
    git -C "$ASSETS_DIR" pull --ff-only origin "$ASSETS_BRANCH"
else
    if [[ -e "$ASSETS_DIR" ]]; then
        log ERROR "$ASSETS_DIR exists but is not a Git repository."
        exit 1
    fi

    log INFO "Cloning SRB2 assets branch: $ASSETS_BRANCH"

    git clone \
        --branch "$ASSETS_BRANCH" \
        --single-branch \
        https://git.do.srb2.org/STJr/srb2assets-public.git \
        "$ASSETS_DIR"
fi

log OK "SRB2 assets branch '$ASSETS_BRANCH' is ready."

# 8. Install assets
log INFO "Installing assets into $ASSETS_DEST."
mkdir -p "$ASSETS_DEST"

# '/.' copies hidden files as well.
cp -a "$ASSETS_DIR"/. "$ASSETS_DEST"/

if [[ ! -f "$ASSETS_DEST/srb2.pk3" ]]; then
    log ERROR "Required file was not found: $ASSETS_DEST/srb2.pk3"
    log ERROR "Check that the selected assets branch contains srb2.pk3."
    exit 1
fi

log OK "Assets installed, including srb2.pk3."


# The '/.' syntax copies hidden files as well.
cp -a "$ASSETS_DIR"/. "$ASSETS_DEST"/

log OK "Assets installed."

# 9. Create executable symlink
log INFO "Installing executable symlink at $INSTALL_PATH."
sudo mkdir -p "$(dirname "$INSTALL_PATH")"
sudo ln -sfn "$SRB2_DIR/bin/lsdl2srb2" "$INSTALL_PATH"

log OK "Executable installed."

# 10. Create desktop entry
log INFO "Creating desktop entry."
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Sonic Robo Blast 2
Comment=Sonic Robo Blast 2
Exec=$INSTALL_PATH
Terminal=false
Categories=Game;
EOF

log OK "Desktop entry created at $DESKTOP_FILE."

# 11. Final validation
log INFO "Validating installation."

if [[ ! -x "$SRB2_DIR/bin/lsdl2srb2" ]]; then
    log ERROR "Expected executable was not found or is not executable:"
    log ERROR "$SRB2_DIR/bin/lsdl2srb2"
    exit 1
fi

if [[ ! -L "$INSTALL_PATH" ]]; then
    log ERROR "Executable symlink was not created: $INSTALL_PATH"
    exit 1
fi

log OK "SRB2 installation completed successfully."
log INFO "You can launch the game with: srb2"
