#!/usr/bin/env python3

import subprocess
import sys

import requests


def fetch_compromised_packages(url):
    """Fetch the list of compromised packages from the URL"""
    try:
        response = requests.get(url)
        response.raise_for_status()
        # Parse the markdown content to extract package names
        lines = response.text.split("\n")
        packages = set()

        for line in lines:
            line = line.strip()
            # Skip empty lines and markdown formatting
            if (
                line
                and not line.startswith("#")
                and not line.startswith("|")
                and not line.startswith("-")
            ):
                # Extract package name (first word or before any whitespace)
                pkg_name = line.split()[0] if line.split() else None
                if pkg_name and pkg_name not in ("Package", "Name"):
                    packages.add(pkg_name)

        return packages
    except requests.RequestException as e:
        print(f"Error fetching compromised packages: {e}", file=sys.stderr)
        sys.exit(1)


def get_installed_packages():
    """Get list of manually installed packages (AUR packages)"""
    try:
        result = subprocess.run(
            ["pacman", "-Qm"], capture_output=True, text=True, check=True
        )
        packages = set()

        for line in result.stdout.strip().split("\n"):
            if line:
                # pacman -Qm outputs: "package_name version"
                pkg_name = line.split()[0]
                packages.add(pkg_name)

        return packages
    except subprocess.CalledProcessError as e:
        print(f"Error fetching installed packages: {e}", file=sys.stderr)
        sys.exit(1)


def find_compromised_installed(bad_pkgs, installed_pkgs):
    """Find intersection of compromised and installed packages"""
    return bad_pkgs.intersection(installed_pkgs)


def main():
    url = "https://md.archlinux.org/s/SxbqukK6IA"

    print("Fetching list of compromised packages...")
    compromised = fetch_compromised_packages(url)
    print(f"Found {len(compromised)} compromised packages")

    print("Fetching list of installed packages...")
    installed = get_installed_packages()
    print(f"Found {len(installed)} manually installed packages")

    # Find compromised packages that are installed
    found_compromised = find_compromised_installed(compromised, installed)

    if found_compromised:
        print("\n⚠️  WARNING: The following compromised packages are installed:")
        for pkg in sorted(found_compromised):
            print(f"  - {pkg}")
        print(f"\nTotal: {len(found_compromised)} compromised package(s) found")
        return 1
    else:
        print("\n✓ Good news! No compromised packages detected.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
