#!/usr/bin/env python3
"""
install-jellyfin-openrc.py
Usage:
  sudo MEDIA_DIR=/path/to/media python3 install-jellyfin-openrc.py
Optional environment overrides:
  IMAGE, CONTAINER_NAME, SERVICE_NAME, JELLYFIN_HTTP_PORT, JELLYFIN_HTTPS_PORT,
  MEDIA_DIR, CONFIG_DIR, CACHE_DIR, PODMAN_BIN, OPENRC_INIT_DIR

Flags:
  --test-machine   : run podman machine init/start and execute podman commands inside it (requires podman)
"""

import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import shutil
import subprocess
from pathlib import Path

from lib.utils import (
    check_required_apps,
    create_podman_container,
    ensure_root,
    pull_image,
    rollback_all,
    set_ownership_array,
    setup_directories,
    setup_rc_service,
    setup_test_machine,
    start_service,
)

# --- Defaults (can be overridden via env) ---
IMAGE = os.environ.get("IMAGE", "docker.io/jellyfin/jellyfin:latest")
CONTAINER_NAME = os.environ.get("CONTAINER_NAME", "jellyfin")
SERVICE_NAME = os.environ.get("SERVICE_NAME", "jellyfin-podman")
JELLYFIN_HTTP_PORT = os.environ.get("JELLYFIN_HTTP_PORT", "8096")
JELLYFIN_HTTPS_PORT = os.environ.get("JELLYFIN_HTTPS_PORT", "8920")
MEDIA_DIR = Path(os.environ.get("MEDIA_DIR", "/srv/media"))
CONFIG_DIR = Path(os.environ.get("CONFIG_DIR", "/var/lib/jellyfin/config"))
CACHE_DIR = Path(os.environ.get("CACHE_DIR", "/var/lib/jellyfin/cache"))
PODMAN_BIN = Path(os.environ.get("PODMAN_BIN", "/usr/bin/podman"))
OPENRC_INIT_DIR = Path(os.environ.get("OPENRC_INIT_DIR", "/etc/init.d"))

# Init script content (single-quoted in shell version; keep consistent)
INIT_SCRIPT = """#!/sbin/openrc-run
description="Manage Jellyfin (Podman container)"

name="jellyfin-podman"
command="/usr/bin/podman"
command_args="start -a jellyfin"
pidfile="/run/${RC_SVCNAME}.pid"

depend() {
  need localmount
  use net
}

start_pre() {
  # Ensure container exists (no-op if already present)
  /usr/bin/podman container exists jellyfin || /usr/bin/podman create \\
    --name jellyfin \\
    --restart=always \\
    -p 8096:8096/tcp \\
    -p 8920:8920/tcp \\
    -v /var/lib/jellyfin/config:/config \\
    -v /var/lib/jellyfin/cache:/cache \\
    -v /srv/media:/media:ro \\
    docker.io/jellyfin/jellyfin:latest
}
"""


def main():
    rollback_stack = []
    test_machine = False
    if "--test-machine" in sys.argv:
        test_machine = True
        setup_test_machine(rollback_stack, test_machine)

    required_apps = ["podman", "podman-compose"]

    ensure_root()
    check_required_apps(required_apps)

    try:
        DIRS = [MEDIA_DIR, CONFIG_DIR, CACHE_DIR]
        # 1) Ensure dirs exist
        rollback_stack = setup_directories(DIRS, rollback_stack)

        # set ownership (best-effort)
        rollback_stack = set_ownership_array(DIRS, 1000, 1000, rollback_stack)

        # 2) Pull image
        rollback_stack = pull_image(str(PODMAN_BIN), IMAGE, rollback_stack)

        # 3) Create container if not exists
        rollback_stack = create_podman_container(
            str(PODMAN_BIN),
            CONTAINER_NAME,
            JELLYFIN_HTTP_PORT,
            JELLYFIN_HTTPS_PORT,
            str(CONFIG_DIR),
            str(CACHE_DIR),
            str(MEDIA_DIR),
            IMAGE,
            rollback_stack,
        )

        # 4) Write OpenRC service script atomically
        rollback_stack = setup_rc_service(
            rollback_stack,
            OPENRC_INIT_DIR,
            SERVICE_NAME,
            INIT_SCRIPT,
        )

        # 5) Enable service in default runlevel and start it
        rollback_stack = start_service(rollback_stack, SERVICE_NAME, OPENRC_INIT_DIR)

        # Success: clear rollback stack
        rollback_stack.clear()
        print()
        host_ip = (
            subprocess.run(["hostname", "-I"], stdout=subprocess.PIPE, text=True)
            .stdout.strip()
            .split()[0]
            if shutil.which("hostname")
            else "<host-ip>"
        )
        print(
            f"Jellyfin should now be created and started (container name: {CONTAINER_NAME})."
        )
        print()
        print(
            f"Access (LAN): http://{host_ip}:{JELLYFIN_HTTP_PORT}  (or https on port {JELLYFIN_HTTPS_PORT})"
        )
        print()
        print("Variables used:")
        print(f" MEDIA_DIR={MEDIA_DIR}")
        print(f" CONFIG_DIR={CONFIG_DIR}")
        print(f" CACHE_DIR={CACHE_DIR}")
        print()
        print("Notes:")
        print(" - SELinux is NOT modified by this script.")
        print(" - Media is mounted read-only into the container (/media).")
        print(
            " - To change networking to host mode, edit creation options accordingly."
        )
        print()
        print("To manage container manually:")
        print(f" {PODMAN_BIN} ps -a")
        print(f" {PODMAN_BIN} logs -f {CONTAINER_NAME}")
        print(f" {PODMAN_BIN} stop {CONTAINER_NAME}")
        print(f" {PODMAN_BIN} start {CONTAINER_NAME}")

    except Exception as e:
        print("Error encountered during install:", str(e), file=sys.stderr)
        print("Rolling back changes...", file=sys.stderr)
        rollback_all(rollback_stack)
        sys.exit(1)


if __name__ == "__main__":
    main()
