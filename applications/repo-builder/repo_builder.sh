#!/bin/bash
set -euo pipefail

CPU_ARCH="${1:-x86_64}"
SIGN="${2:-FALSE}"

# Paths
SRC_DIR="${SRC:-/src}"
VOID_PKGS="${SRC_DIR}/void-packages"
PKG_SRC="/home/media/shared/Users/$USER/repos/repository/pkgs"
SHLIBS="/home/media/shared/Users/$USER/repos/repository/common/shlibs"
OUT_DIR="${SRC_DIR}/binpkgs"
HOSTDIR="${SRC_DIR}/hostdir"

# Package recipes to copy and build
PKGS=(
    hyprland-protocols
    hyprwayland-scanner
    hyprutils
    hyprgraphics
    hyprlang
    hyprcursor
    hyprpicker
    aquamarine
    hyprwire
    hyprland-guiutils
    hyprtoolkit
    glaze
    hyprland
    hyprland-qt-support
    hyprland-qtutils
    xdg-desktop-portal-hyprland
    freesmlauncher
    brave-browser
    brave-origin
    linux-cachy-bore
    noctalia
    noctalia-greeter
)

echo "==> Architecture : $CPU_ARCH"
echo "==> void-packages: $VOID_PKGS"
echo "==> Custom pkgs  : $PKG_SRC"
echo "==> Output       : $OUT_DIR"

mkdir -p "$OUT_DIR" "$HOSTDIR"

# 1. Ensure we have a void-packages tree
if [[ ! -x "$VOID_PKGS/xbps-src" ]]; then
    echo "==> Cloning void-packages (shallow)…"
    git clone --depth=1 https://github.com/void-linux/void-packages.git "$VOID_PKGS"
fi

cd "$VOID_PKGS"

# ------------------------------------------------------------------
# Update common/shlibs
# ------------------------------------------------------------------
echo "==> Updating common/shlibs"

# Make sure we start from the official file
git checkout -- common/shlibs 2>/dev/null || true

# Remove any old versions of the libraries we are overriding
sed -i \
    -e '/libhyprutils\.so\./d' \
    -e '/libhyprlang\.so\./d' \
    -e '/libhyprgraphics\.so\./d' \
    -e '/libhyprtoolkit\.so\./d' \
    -e '/libaquamarine\.so\./d' \
    -e '/libhyprcursor\.so\./d' \
    -e '/libhyprwire\.so\./d' \
    -e '/libbge\.so\./d' \
    -e '/libmalcontent/d' \
    -e '/pam_malcontent/d' \
    -e '/libgsystemservice/d' \
    -e '/libglib-testing/d' \
    common/shlibs

# Append your custom mappings
cat >> common/shlibs << EOF
libbge.so.0 bazaar-0.8.1_1
libmalcontent-0.so.0 malcontent-0.14_1
pam_malcontent.so malcontent-0.14_1
libmalcontent-ui-1.so.1 malcontent-0.14_1
libnss_malcontent.so.2 malcontent-0.14_1
libgsystemservice-0.so.0 libgsystemservice-0.3.0_1
libglib-testing-0.so.0 libglib-testing-0.2.0_1
libhyprutils.so.13 hyprutils-0.14.2_1
libhyprlang.so.2 hyprlang-0.6.8_2
libhyprgraphics.so.4 hyprgraphics-0.5.1_2
libhyprtoolkit.so.6 hyprtoolkit-0.6.0_1
libaquamarine.so.14 aquamarine-0.15.0_1
libhyprcursor.so.0 hyprcursor-0.1.13_2
libhyprwire.so.3 hyprwire-0.3.1_2
EOF

# 2. Copy / update your custom packages into srcpkgs/
echo "==> Syncing custom packages…"
for pkg in "${PKGS[@]}"; do
    if [[ -d "$PKG_SRC/$pkg" ]]; then
        rm -rf "srcpkgs/$pkg"
        cp -a "$PKG_SRC/$pkg" "srcpkgs/"
        # Create devel symlink if the template defines a -devel subpackage
        if grep -q "${pkg}-devel_package()" "srcpkgs/$pkg/template" 2>/dev/null; then
            ln -sfn "$pkg" "srcpkgs/${pkg}-devel"
        fi
    else
        echo "WARNING: $pkg not found in $PKG_SRC"
    fi
done

# 3. Bootstrap masterdir if needed
MASTERDIR="masterdir-${CPU_ARCH}"

if [[ ! -d "$MASTERDIR" ]]; then
    echo "==> Bootstrapping masterdir for $CPU_ARCH"
    if [[ "$CPU_ARCH" == "x86_64" ]]; then
        ./xbps-src -m "$MASTERDIR" binary-bootstrap
    else
        # Enable cross build
        ./xbps-src -a "$CPU_ARCH" -m "$MASTERDIR" binary-bootstrap
    fi
fi

# 4. Build the packages
for pkg in "${PKGS[@]}"; do
    echo "==> Building $pkg ($CPU_ARCH)"
    if [[ "$CPU_ARCH" == "x86_64" ]]; then
        ./xbps-src -m "$MASTERDIR" -H "$HOSTDIR" pkg "$pkg"
    else
        ./xbps-src -a "$CPU_ARCH" -m "$MASTERDIR" -H "$HOSTDIR" pkg "$pkg"
    fi
done

# 5. Collect + index + sign (same as before)
echo "==> Collecting packages…"
find "$HOSTDIR/binpkgs" -name '*.xbps' -exec cp -av {} "$OUT_DIR/" \;

cd "$OUT_DIR"
xbps-rindex -a ./*.xbps || true

if [[ "$SIGN" == "TRUE" ]]; then
    if [[ ! -f "$HOME/private.pem" ]]; then
        echo "ERROR: $HOME/private.pem not found"
        exit 1
    fi
    echo "==> Signing repository"
    xbps-rindex --privkey "$HOME/private.pem" \
                --signedby "Your Name <you@example.com>" \
                --sign .
    xbps-rindex --privkey "$HOME/private.pem" --sign-pkg ./*.xbps
fi

echo "==> Done"
ls -l
