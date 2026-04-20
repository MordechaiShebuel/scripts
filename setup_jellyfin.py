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
import shutil
import subprocess
import sys
from pathlib import Path

from utils import (
    atomic_write,
    check_required_apps,
    ensure_root,
    push_rollback,
    rollback_all,
    run,
    safe_mkdir,
    setup_test_machine,
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
    ROLLBACK_STACK = []
    test_machine = False
    if "--test-machine" in sys.argv:
        test_machine = True

    required_apps = ["podman", "podman-compose"]

    ensure_root()
    check_required_apps(required_apps)

    # If test_machine requested, init/start podman machine
    setup_test_machine(ROLLBACK_STACK, test_machine)

    created_paths = []
    try:
        # 1) Ensure dirs exist
        for p in (MEDIA_DIR, CONFIG_DIR, CACHE_DIR):
            created = safe_mkdir(p)
            if created:
                created_paths.extend(created)
                # rollback: remove the directory only if it is empty to avoid deleting user data
                ROLLBACK_STACK = push_rollback(
                    lambda p=p: p.exists() and not any(p.iterdir()) and p.rmdir(),
                    ROLLBACK_STACK,
                )

        # set ownership (best-effort)
        try:
            for p in (MEDIA_DIR, CONFIG_DIR, CACHE_DIR):
                # chown to 1000:1000 like original; record previous ownership is complex, skip restoring
                os.chown(str(p), 1000, 1000)
        except Exception:
            # non-fatal; avoid failing if chown is not allowed
            pass

        # 2) Pull image
        print(f"Pulling Jellyfin image: {IMAGE}")
        run([str(PODMAN_BIN), "pull", IMAGE])
        # rollback: remove image
        ROLLBACK_STACK = push_rollback(
            lambda: run([str(PODMAN_BIN), "rmi", "-f", IMAGE]), ROLLBACK_STACK
        )

        # 3) Create container if not exists
        exists = run([str(PODMAN_BIN), "container", "exists", CONTAINER_NAME])
        if exists.returncode == 0:
            print(f"Container '{CONTAINER_NAME}' already exists.")
        else:
            print(
                f"Creating container '{CONTAINER_NAME}' with port mappings (LAN-only)."
            )
            run(
                [
                    str(PODMAN_BIN),
                    "create",
                    "--name",
                    CONTAINER_NAME,
                    "--restart=always",
                    "-p",
                    f"{JELLYFIN_HTTP_PORT}:8096/tcp",
                    "-p",
                    f"{JELLYFIN_HTTPS_PORT}:8920/tcp",
                    "-v",
                    f"{CONFIG_DIR}:/config",
                    "-v",
                    f"{CACHE_DIR}:/cache",
                    "-v",
                    f"{MEDIA_DIR}:/media:ro",
                    IMAGE,
                ]
            )
            ROLLBACK_STACK = push_rollback(
                lambda: run([str(PODMAN_BIN), "rm", "-f", CONTAINER_NAME]),
                ROLLBACK_STACK,
            )

        # 4) Write OpenRC service script atomically
        INIT_PATH = OPENRC_INIT_DIR / SERVICE_NAME
        if not OPENRC_INIT_DIR.exists():
            OPENRC_INIT_DIR.mkdir(parents=True, exist_ok=True)
            ROLLBACK_STACK = push_rollback(
                lambda: (
                    OPENRC_INIT_DIR.rmdir()
                    if not any(OPENRC_INIT_DIR.iterdir())
                    else None
                ),
                ROLLBACK_STACK,
            )

        # If file already exists, back it up (so we can restore)
        backup_path = None
        if INIT_PATH.exists():
            backup_path = INIT_PATH.with_suffix(".bak")
            shutil.copy2(str(INIT_PATH), str(backup_path))
            ROLLBACK_STACK = push_rollback(
                lambda: (
                    os.replace(str(backup_path), str(INIT_PATH))
                    if backup_path.exists()
                    else None
                ),
                ROLLBACK_STACK,
            )
        else:
            ROLLBACK_STACK = push_rollback(
                lambda: INIT_PATH.unlink() if INIT_PATH.exists() else None,
                ROLLBACK_STACK,
            )

        atomic_write(INIT_PATH, INIT_SCRIPT, mode=0o755)
        print(f"OpenRC service script written to {INIT_PATH}")

        # 5) Enable service in default runlevel and start it
        try:
            run(["rc-update", "add", SERVICE_NAME, "default"])
            ROLLBACK_STACK = push_rollback(
                lambda: run(["rc-update", "del", SERVICE_NAME, "default"]),
                ROLLBACK_STACK,
            )
        except subprocess.CalledProcessError:
            # non-fatal; continue but note we didn't add to default runlevel
            pass

        try:
            run(["rc-service", SERVICE_NAME, "start"])
            # rollback: try to stop service
            ROLLBACK_STACK = push_rollback(
                lambda: run(["rc-service", SERVICE_NAME, "stop"]), ROLLBACK_STACK
            )
        except subprocess.CalledProcessError:
            print(
                f"Warning: starting service failed; try 'rc-service {SERVICE_NAME} start' manually.",
                file=sys.stderr,
            )

        # Success: clear rollback stack
        ROLLBACK_STACK.clear()
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
        rollback_all(ROLLBACK_STACK)
        sys.exit(1)


if __name__ == "__main__":
    main()
