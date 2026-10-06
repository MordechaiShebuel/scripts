#!/bin/bash

modify_zshrc_qt_theme() {
  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  local marker="# QT Platform and Theme Configuration"

  if [[ -f "$zshrc" ]] && grep -Fq "$marker" "$zshrc"; then
    echo "QT theme configuration already exists in $zshrc"
    return 0
  fi

  cat >> "$zshrc" <<'EOF'

# QT Platform and Theme Configuration
export QT_QPA_PLATFORMTHEME=kvantum
export QT_QPA_PLATFORM=wayland
export QT_STYLE_OVERRIDE=kvantum
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# QT5 Support (if still using QT5 apps)
export QT5_QPA_PLATFORMTHEME=kvantum

# Wayland-specific (important for Hyprland)
export QT_WAYLAND_DISABLE_WINDOWDECORATION=0
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib/qt6/plugins
EOF

  echo "Added QT theme configuration to $zshrc"
}
