#!/bin/sh
# List installed packages and the repository each was installed from.

printf '%-40s %s\n' "PACKAGE" "REPOSITORY"
printf '%-40s %s\n' "----------------------------------------" "----------------------------------------"

xbps-query -l | awk '{print $2}' | while read -r pkgver; do
    name=$(xbps-uhelper getpkgname "$pkgver")
    repo=$(xbps-query -p repository "$name" 2>/dev/null)
    printf '%-40s %s\n' "$name" "${repo:-unknown}"
done
