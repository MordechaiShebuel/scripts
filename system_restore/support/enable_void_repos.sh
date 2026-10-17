#!/bin/bash

if ! {
    test -f /etc/xbps.d/noid-xbps-repo.conf &&
    test -f /etc/xbps.d/linuxnauta.conf &&
    test -f /etc/xbps.d/voiders-dev-repo.conf &&
    test -f /etc/xbps.d/neko-void.conf &&
    sudo xbps-query -p pkgver void-repo-nonfree >/dev/null 2>&1 &&
    sudo xbps-query -p pkgver void-repo-multilib >/dev/null 2>&1
}; then
    # Noid Repo
    echo "repository=https://github.com/noid-linux/xbps-repo/releases/latest/download" |
        sudo tee /etc/xbps.d/noid-xbps-repo.conf >/dev/null

    # Linux Nauta
    echo "repository=https://voidrepo.linuxnauta.com" |
        sudo tee /etc/xbps.d/linuxnauta.conf >/dev/null

    # Voiders
    # echo "repository=https://repo.voiders.dev" |
    #     sudo tee /etc/xbps.d/voiders-dev-repo.conf >/dev/null

    # Lazy Linux
    echo "repository=https://github.com/lazylinuxos/lazy-repo/releases/latest/download/" |
        sudo tee /etc/xbps.d/lazy-repo.conf >/dev/null

    # Neko Linux
    echo "repository=https://sourceforge.net/projects/neko-void/files/repo" |
        sudo tee /etc/xbps.d/neko-void.conf >/dev/null

    # Blackhole Linux
    echo "repository=https://github.com/Event-Horizon-VL/blackhole-vl" |
    sudo tee /etc/xbps.d/blowhole-void.conf >/dev/null
    # Hyprland specific
    # echo "repository=https://raw.githubusercontent.com/sofijacom/hyprland-void/repository-x86_64-glibc" | sudo tee /etc/xbps.d/hyprland-void.conf

    sudo xbps-install -Syu void-repo-nonfree void-repo-multilib
fi

    sudo xbps-install -Syu

    sudo xbps-install -Su
