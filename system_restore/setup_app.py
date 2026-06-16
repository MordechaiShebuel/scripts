# Python script to install Nym and setup daemon for Artix/Devuan
# Version 1.1 - functional

import os
import sys

import click

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

# --- Defaults (can be overridden via env) ---
OPENRC_INIT_DIR = Path(os.environ.get("OPENRC_INIT_DIR", "/etc/init.d"))


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


@click.command()
@click.option(
    "--test-machine", is_flag=True, help="Simulate installation on a test machine"
)
@click.option("--service-name", help="Name of the service to start and install")
@click.option("--apps", help="Name of the app to install")
def main(test_machine: bool, service_name: str | None, apps: str | None):
    rollback_stack = []

    required_apps: list[str] = apps.split(",") if apps else []

    if not service_name and len(required_apps) == 0:
        print("No service name or apps specified", file=sys.stderr)
        sys.exit(1)
    else:
        service_name = str(service_name)

    test_machine = False
    if "--test-machine" in sys.argv:
        required_apps.append("podman")
        required_apps.append("podman-compose")
        test_machine = True
        # TODO: Need to determine if this would allow simulation of nym install
        #
    print(
        f"Download and install {', '.join(required_apps)}, get service running for {service_name} on OpenRC"
    )

    try:
        distro = detect_distro()

        if distro == "arch":
            required_apps.extend(["trizen", "pamac"])
        elif distro == "debian":
            # Install Nym VPN App
            # required_apps.extend(["nym-vpn-app", "nym-vpnd"])
            rollback_stack = enable_nym_repo(rollback_stack)
        else:
            print("Unsupported distro: ", distro, file=sys.stderr)
            sys.exit(1)

        SKIP_PROCESS = check_apps(required_apps) and check_service(service_name)
        if SKIP_PROCESS:
            print(
                f"{', '.join(required_apps)} is already installed and running, skipping install..."
            )
            sys.exit(0)

        rollback_stack = install_required_apps(rollback_stack, required_apps, distro)

        with open(f"../service-files/{service_name}", "r") as file:
            CONFIG = file.read().replace("\n", "")

        rollback_stack = setup_rc_service(
            rollback_stack, OPENRC_INIT_DIR, service_name, CONFIG
        )
        rollback_stack = start_service(rollback_stack, service_name, OPENRC_INIT_DIR)
    except Exception as e:
        print("Error encountered during install:", str(e), file=sys.stderr)
        print("Rolling back changes...", file=sys.stderr)
        traceback.print_exc()
        rollback_all(rollback_stack)
        sys.exit(1)


if __name__ == "__main__":
    main()
