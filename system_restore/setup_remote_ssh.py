# Python script to install Nym and setup daemon for Artix/Devuan
# Version 1.1 - functional
# Made improvements to make script more robust and modular
# TODO: add way to test in podman container

import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import traceback
from pathlib import Path

from lib.utils import (
    check_apps,
    check_service,
    detect_distro,
    install_required_apps,
    rollback_all,
    start_service,
)

# --- Defaults (can be overridden via env) ---
OPENRC_INIT_DIR = Path(os.environ.get("OPENRC_INIT_DIR", "/etc/init.d"))
SERVICE_NAME = os.environ.get("SERVICE_NAME", "sshd")
SERVICE_CMD = os.environ.get("SERVICE_CMD", "rc-service")

def main():
    global SERVICE_NAME

    rollback_stack = []
    required_apps = []

    test_machine = False
    if "--test-machine" in sys.argv:
        required_apps.append("podman")
        required_apps.append("podman-compose")
        test_machine = True
        # TODO: Need to determine if this would allow simulation of nym install

    print("Download and install SSH, get service running for SSHD on OpenRC")

    try:
        distro = detect_distro()
        if distro == "arch":
            required_apps.append("trizen")
            required_apps.append("pamac")
            required_apps.append("openssh-openrc")
            required_apps.append("openssh")
            #required_apps.append("dropbear")
            svc_name = SERVICE_NAME
            svc_cmd = SERVICE_CMD
        elif distro == "debian":
            required_apps.append('ssh')
            # Install Nym VPN App
            # required_apps = ["nym-vpn-app", "nym-vpnd"]
            # rollback_stack = enable_nym_repo(rollback_stack)
            print("No extra apps needed for Debian-based distro.")
            svc_name = 'ssh'
            svc_cmd = SERVICE_CMD
        elif distro == "void":
            required_apps.append('openssh')
            svc_name = 'ssh'
            svc_cmd = 'sv'
        else:
            print("Unsupported distro: ", distro, file=sys.stderr)
            sys.exit(1)

        SKIP_APPS_AND_SERVICE = check_apps(required_apps, distro) and check_service(
            svc_name, svc_cmd
        )

        if SKIP_APPS_AND_SERVICE:
            print("Apps and service already installed, skipping installation.")
            sys.exit(0)

        if not check_apps(required_apps, distro):
            rollback_stack = install_required_apps(
                rollback_stack, required_apps, distro
            )

        if not check_service(svc_name, svc_cmd):
            rollback_stack = start_service(
                rollback_stack, SERVICE_NAME, OPENRC_INIT_DIR
            )

    except Exception as e:
        print("Error encountered during install:", str(e), file=sys.stderr)
        print("Rolling back changes...", file=sys.stderr)
        traceback.print_exc()
        rollback_all(rollback_stack)
        sys.exit(1)

    print("SSH Services installed and daemon started.")


if __name__ == "__main__":
    main()
