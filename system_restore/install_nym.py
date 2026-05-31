# Python script to install Nym and setup daemon for Artix/Devuan
# Version 1.1 - functional

import os
import sys
from calendar import c

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import traceback
from collections.abc import Callable
from pathlib import Path

from lib.utils import (
    RollbackAction,
    check_apps,
    check_service,
    detect_distro,
    install_required_apps,
    rollback_all,
    run,
    setup_rc_service,
    start_service,
)

NYMD_CONFIG = """#!/sbin/openrc-run
name="nym-vpnd"
description="NymVPN daemon"

# Path to the binary
command="/usr/bin/nym-vpnd"
command_args="-v run-as-service"

pidfile="/run/nym-vpnd.pid"
command_background="yes"

depend() {    print("This is where the problem is.")
input()
     need dbus
     use net
     after firewall
}

start_pre() {
     checkpath --directory --mode 0755 /run
}

supervise() {
     start-stop-daemon --start --exec "${command}" --background --make-pidfile --pidfile "${pidfile}" -- ${command_args}
}

stop() {
     start-stop-daemon --stop --pidfile "${pidfile}" --retry TERM/5/KILL/5
     rm -f "${pidfile}"
}"""

# --- Defaults (can be overridden via env) ---
OPENRC_INIT_DIR = Path(os.environ.get("OPENRC_INIT_DIR", "/etc/init.d"))
SERVICE_NAME = os.environ.get("SERVICE_NAME", "nym-vpnd")


def enable_nym_repo(
    rollback_stack: list[RollbackAction],
) -> list[RollbackAction]:
    """Enable the Nym repository for Debian-based distros."""
    # Add GPG key and repository
    cmd = 'sudo curl -s --compressed "https://apt.nymtech.net/nymtech.gpg" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/nymtech.gpg > /dev/null'

    run(cmd, shell=True)

    # Add repository
    cmd = "sudo tee /etc/apt/sources.list.d/nymtech.list > /dev/null << 'EOF'\ndeb [arch=amd64] https://apt.nymtech.net/ stable main\neof"
    run(cmd, shell=True)

    return rollback_stack


# This is not needed with the repo add, but it could be expanded to support other distros
# def download_and_install_nym_vpnd(rollback_stack):
#     """Download and install Nym VPND from GitHub releases."""
#     import tarfile
#     import tempfile
#     import urllib.request

#     version = "v1.29.3"
#     url = f"https://github.com/nymtech/nym-vpn-client/releases/download/nym-vpn-core-{version}/nym-vpn-core-{version}_linux_x86_64.tar.gz"

# with tempfile.TemporaryDirectory() as tmpdir:
#     tar_path = Path(tmpdir) / "nym-vpn-core.tar.gz"

# Download
# print(f"Downloading Nym VPND from {url}...")
# urllib.request.urlretrieve(url, tar_path)

# Extract
# print("Extracting Nym VPND...")
# with tarfile.open(tar_path, "r:gz") as tar:
#     tar.extractall(tmpdir)

# Find the binary
# extracted_dir = Path(tmpdir) / f"nym-vpn-core-{version}_linux_x86_64"
# binary_path = extracted_dir / "nym-vpnd"

# if not binary_path.exists():
#     raise FileNotFoundError(f"nym-vpnd binary not found in {extracted_dir}")

# Install to /usr/bin
# cmd = def start_service(rollback_stack: List[Callable[[], None]]) -> List[Callable[[], None]]:
#     # Fix Service File

#     INIT_PATH = OPENRC_INIT_DIR / SERVICE_NAME
#     cmd = f"sudo chmod +x {INIT_PATH}"
#     run(cmd, shell=True)

#     cmd = f"sudo rc-update add {SERVICE_NAME} default"

#     def remove_service():
#         cmd = f"sudo rc-update del {INIT_PATH} default"
#         run(cmd, shell=True)

#     rollback_stack = push_rollback(remove_service, rollback_stack)
#     run(cmd, shell=True)

#     # Start service
#     cmd = f"sudo rc-service {SERVICE_NAME} start"

#     def stop_service():
#         cmd = f"sudo rc-service {SERVICE_NAME} stop"
#         run(cmd, shell=True)

#     rollback_stack = push_rollback(stop_service, rollback_stack)
#     run(cmd, shell=True)

#     return rollback_stackf"sudo install -m 755 {binary_path} /usr/bin/nym-vpnd"
# run(cmd, shell=True)
# print("Nym VPND installed to /usr/bin/nym-vpnd")

# Rollback function
#     def remove_nym_vpnd():
#         cmd = "sudo rm -f /usr/bin/nym-vpnd"
#         run(cmd, shell=True)

#     rollback_stack = push_rollback(remove_nym_vpnd, rollback_stack)

# return rollback_stack


def main():
    rollback_stack = []

    required_apps = []
    install_nym_vpnd_manual = False

    test_machine = False
    if "--test-machine" in sys.argv:
        required_apps.append("podman")
        required_apps.append("podman-compose")
        test_machine = True
        # TODO: Need to determine if this would allow simulation of nym install

    print("Download and install Nym, get service running for nym-vpnd on OpenRC")

    try:
        distro = detect_distro()

        if distro == "arch":
            required_apps = ["trizen", "pamac", "nym-vpnd-bin", "nym-vpn-app-bin"]
        elif distro == "debian":
            # Install Nym VPN App
            required_apps = ["nym-vpn-app", "nym-vpnd"]
            rollback_stack = enable_nym_repo(rollback_stack)
        else:
            print("Unsupported distro: ", distro, file=sys.stderr)
            sys.exit(1)

        SKIP_PROCESS = check_apps(required_apps) and check_service(SERVICE_NAME)
        if SKIP_PROCESS:
            print("Nym is already installed and running, skipping install...")
            sys.exit(0)

        rollback_stack = install_required_apps(rollback_stack, required_apps, distro)

        rollback_stack = setup_rc_service(
            rollback_stack, OPENRC_INIT_DIR, SERVICE_NAME, NYMD_CONFIG
        )
        rollback_stack = start_service(rollback_stack, SERVICE_NAME, OPENRC_INIT_DIR)
    except Exception as e:
        print("Error encountered during install:", str(e), file=sys.stderr)
        print("Rolling back changes...", file=sys.stderr)
        traceback.print_exc()
        rollback_all(rollback_stack)
        sys.exit(1)


if __name__ == "__main__":
    main()
