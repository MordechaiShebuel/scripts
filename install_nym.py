# Python script to install Nym and setup daemon for Artix
import os
import shutil
from utils import run, push_rollback, rollback_all, atomic_write, safe_mkdir, ensure_root, check_required_apps

# --- Defaults (can be overridden via env) ---
OPENRC_INIT_DIR = Path(os.environ.get("OPENRC_INIT_DIR", "/etc/init.d"))
SERVICE_NAME = os.environ.get("SERVICE_NAME", "nym-vpnd")

ROLLBACK_STACK = []

# install script
def install_nym():
    cmd = "trizen -S nym-vpnd-bin nym-vpn-app-bin --noconfirm"
    run(cmd)
    def remove_nym():
        try:
            cmd = "trizen -R nym-vpnd-bin nym-vpn-app-bin --noconfirm"
            run(cmd)
        except Exception:
            pass
    ROLLBACK_STACK = push_rollback(remove_nym)

def setup_rc():
    # Create config for OpenRC
    nymd_config = ("#!/sbin/openrc-run"
    "name=\"nym-vpnd\""
    "description=\"NymVPN daemon\""
    "command=\"/usr/bin/nym-vpnd\""
    "command_args=\"-v run-as-service\""
    "pidfile=\"/run/${RC_SVCNAME}.pid\""
    "command_background=\"yes\""
    "depend() {"
    "need dbus"
    "use net"
    "after firewall"
    "}"

    "start_pre() {"
    "checkpath --directory --mode 0755 /run"
    "}"

    "supervise() {"
    "start-stop-daemon --start --exec \"${command}\" --background --make-pidfile --pidfile \"${pidfile}\" -- $>"
    "}"

    "stop() {"
    "start-stop-daemon --stop --pidfile \"${pidfile}\" --retry TERM/5/KILL/5"
    "rm -f \"${pidfile}\""
    "}")

    # Define init.d file
    if not OPENRC_INIT_DIR.exists():
        OPENRC_INIT_DIR.mkdir(parents=True, exist_ok=True)
        ROLLBACK_STACK = push_rollback(lambda: OPENRC_INIT_DIR.rmdir() if not any(OPENRC_INIT_DIR.iterdir()) else None, ROLLBACK_STACK)

    INIT_PATH = OPENRC_INIT_DIR / SERVICE_NAME

            # If file already exists, back it up (so we can restore)
    backup_path = None
    if INIT_PATH.exists():
        backup_path = INIT_PATH.with_suffix(".bak")
        shutil.copy2(str(INIT_PATH), str(backup_path))
        ROLLBACK_STACK = push_rollback(lambda: os.replace(str(backup_path), str(INIT_PATH)) if backup_path.exists() else None, ROLLBACK_STACK)
    else:
        ROLLBACK_STACK = push_rollback(lambda: INIT_PATH.unlink() if INIT_PATH.exists() else None, ROLLBACK_STACK)

    # Save output to init.d file
    atomic_write(INIT_PATH, INIT_SCRIPT, mode=0o755)
    print(f"OpenRC service script written to {INIT_PATH}")

def start_service():
    #Create Service
    cmd = 'sudo rc-update add nym-vpnd default'
    def remove_service():
        cmd = 'sudo rc-update del nym-vpnd default'
        run(cmd)

    ROLLBACK_STACK = push_rollback(remove_service, ROLLBACK_STACK)
    run(cmd)

    #Start service
    cmd = 'sudo rc-service nym-vpnd start'

    def stop_service():
        cmd = 'sudo rc-service nym-vpnd stop'
        run(cmd)

    ROLLBACK_STACK = push_rollback(stop_service, ROLLBACK_STACK)
    run(cmd)

def main():

    required_apps = ['trizen']

    test_machine = False
    if "--test-machine" in sys.argv:
        required_apps.append('podman', 'podman-compose')
        test_machine = True

    print("Download and install Nym, get service running for nym-vpnd on OpenRC")

    ensure_root()
    check_required_apps(required_apps)
    try:
        install_nym()
        setup_rc()
        start_service()
    except Exception as e:
        print("Error encountered during install:", str(e), file=sys.stderr)
        print("Rolling back changes...", file=sys.stderr)
        rollback_all(ROLLBACK_STACK)
        sys.exit(1)

if __name__ == "__main__":
    main()
