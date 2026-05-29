# Python script to install Nym and setup daemon for Artix/Devuan
# Version 1.1 - functional

import os
import sys
import traceback
from pathlib import Path

# Add parent direcimport tracebacktory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from lib.utils import (
    RollbackAction,
    app_installed,
    check_apps,
    check_service,
    detect_distro,
    install_apps,
    install_required_apps,
    push_rollback,
    rollback_all,
    run,
    setup_rc_service,
    start_service,
)

SANED_CONFIG = """#!/sbin/openrc-run
command="/usr/sbin/saned"
command_args="-d"
pidfile="/run/saned.pid"
depend() {
  need net
}"""

# --- Defaults (can be overridden via env) ---
OPENRC_INIT_DIR = Path(os.environ.get("OPENRC_INIT_DIR", "/etc/init.d"))
SERVICE_NAME = os.environ.get("SERVICE_NAME", "saned")


def main():
    rollback_stack = []

    required_apps = []

    test_machine = False
    if "--test-machine" in sys.argv:
        required_apps.append("podman")
        required_apps.append("podman-compose")
        test_machine = True
        # TODO: Need to determine if this would allow simulation of nym install

    print("Download and install SANE, get service running for saned on OpenRC")

    try:
        distro = detect_distro()

        if distro == "arch":
            required_apps = ["trizen", "pamac", "sane-utils", "libsane-extras"]
        elif distro == "debian":
            # Install sane App
            required_apps = ["sane-utils", "libsane-extras"]
        else:
            print("Unsupported distro:", distro, file=sys.stderr)
            sys.exit(1)

        SKIP_PROCESS = check_apps(required_apps) and check_service()
        if SKIP_PROCESS:
            print("sane is already installed and running, skipping install...")
            sys.exit(0)

        rollback_stack = install_required_apps(rollback_stack, required_apps, distro)

        rollback_stack = setup_rc_service(
            rollback_stack, OPENRC_INIT_DIR, SERVICE_NAME, SANED_CONFIG
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
