import os
import shutil
from pathlib import Path

from utils import (
    atomic_write,
    ensure_root,
)

# --- Defaults (can be overridden via env) ---
OPENRC_INIT_DIR = Path(os.environ.get("OPENRC_INIT_DIR", "/etc/init.d"))
SERVICE_NAME = os.environ.get("SERVICE_NAME", "nym-vpnd")


def setup_rc():
    # Create config for OpenRC
    nymd_config = (
        "#!/sbin/openrc-run"
        'name="nym-vpnd"'
        'description="NymVPN daemon"'
        'command="/usr/bin/nym-vpnd"'
        'command_args="-v run-as-service"'
        'pidfile="/run/${RC_SVCNAME}.pid"'
        'command_background="yes"'
        "depend() {"
        "need dbus"
        "use net"
        "after firewall"
        "}"
        "start_pre() {"
        "checkpath --directory --mode 0755 /run"
        "}"
        "supervise() {"
        'start-stop-daemon --start --exec "${command}" --background --make-pidfile --pidfile "${pidfile}" -- $>'
        "}"
        "stop() {"
        'start-stop-daemon --stop --pidfile "${pidfile}" --retry TERM/5/KILL/5'
        'rm -f "${pidfile}"'
        "}"
    )

    # Define init.d file
    # TODO: Need to replace these with run() commands.
    if not OPENRC_INIT_DIR.exists():
        OPENRC_INIT_DIR.mkdir(parents=True, exist_ok=True)
        # ROLLBACK_STACK = push_rollback(
        #     lambda: (
        #         OPENRC_INIT_DIR.rmdir() if not any(OPENRC_INIT_DIR.iterdir()) else None
        #     ),
        #     ROLLBACK_STACK,
        # )

    INIT_PATH = OPENRC_INIT_DIR / SERVICE_NAME

    # If file already exists, back it up (so we can restore)
    backup_path = None
    if INIT_PATH.exists():
        backup_path = INIT_PATH.with_suffix(".bak")
        shutil.copy2(str(INIT_PATH), str(backup_path))
        # ROLLBACK_STACK = push_rollback(
        #     lambda: (
        #         os.replace(str(backup_path), str(INIT_PATH))
        #         if backup_path.exists()
        #         else None
        #     ),
        #     ROLLBACK_STACK,
        # )
    else:
        # ROLLBACK_STACK = push_rollback(
        #     lambda: INIT_PATH.unlink() if INIT_PATH.exists() else None, ROLLBACK_STACK
        # )
        print("Things shouldn't get here.")

    # Save output to init.d file
    atomic_write(INIT_PATH, nymd_config, mode=0o755)
    print(f"OpenRC service script written to {INIT_PATH}")


if __name__ == "__main__":
    ensure_root()
    setup_rc()
