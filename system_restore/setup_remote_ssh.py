# Python script to install Nym and setup daemon for Artix
# Version 1.0 - functional
# TODO: add way to test in podman container

import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import traceback
from pathlib import Path

from lib.utils import (
    app_installed,
    install_apps,
    push_rollback,
    rollback_all,
    run,
)

# --- Defaults (can be overridden via env) ---
OPENRC_INIT_DIR = Path(os.environ.get("OPENRC_INIT_DIR", "/etc/init.d"))
SERVICE_NAME = os.environ.get("SERVICE_NAME", "sshd")


def check_service():
    cmd = f"sudo rc-service {SERVICE_NAME} status"
    try:
        status = run(cmd, shell=True, capture=True)
        if "started" in str(status):
            return True
        return False
    except Exception:
        return False


# def app_installed(app):
#     cmd = f"if [[ $(pamac list --installed --quiet | grep {app}) == {app} ]]; then echo 'installed'; else echo 'not installed'; fi"
#     try:
#         installed = run(cmd, shell=True, capture=True)
#         if str(installed).strip() == "installed":
#             return True
#         return False
#     except Exception:
#         return False


def check_apps():
    pkgs = ["openssh-openrc", "openssh", "dropbear"]
    appcheck = 0
    for pkg in pkgs:
        try:
            if app_installed(pkg):
                appcheck = appcheck + 1
        except Exception:
            traceback.print_exc()
            pass
    return appcheck == len(pkgs)


def start_service(ROLLBACK_STACK):
    # Fix Service File
    INIT_PATH = OPENRC_INIT_DIR / SERVICE_NAME
    cmd = f"sudo chmod +x {INIT_PATH}"
    run(cmd, shell=True)

    cmd = f"sudo rc-update add {SERVICE_NAME} default"

    def remove_service():
        cmd = f"sudo rc-update del {SERVICE_NAME} default"
        run(cmd, shell=True)

    ROLLBACK_STACK = push_rollback(remove_service, ROLLBACK_STACK)
    run(cmd, shell=True)

    # Start service
    cmd = f"sudo rc-service {SERVICE_NAME} start"

    def stop_service():
        cmd = f"sudo rc-service {SERVICE_NAME} stop"
        run(cmd, shell=True)

    ROLLBACK_STACK = push_rollback(stop_service, ROLLBACK_STACK)
    run(cmd, shell=True)

    return ROLLBACK_STACK


def main():
    ROLLBACK_STACK = []
    required_apps = ["trizen", "pamac", "openssh-openrc", "openssh", "dropbear"]

    test_machine = False
    if "--test-machine" in sys.argv:
        required_apps.append("podman")
        required_apps.append("podman-compose")
        test_machine = True
        # TODO: Need to determine if this would allow simulation of nym install

    print("Download and install SSH, get service running for SSHD on OpenRC")

    try:
        SKIP_APPS = check_apps()
        if not SKIP_APPS:
            install_apps(required_apps)

        SKIP_SERVICE = check_service()
        if not SKIP_SERVICE:
            start_service(ROLLBACK_STACK)

    except Exception as e:
        print("Error encountered during install:", str(e), file=sys.stderr)
        print("Rolling back changes...", file=sys.stderr)
        traceback.print_exc()
        rollback_all(ROLLBACK_STACK)
        sys.exit(1)

    print("SSH Services installed and daemon started.")


if __name__ == "__main__":
    main()
