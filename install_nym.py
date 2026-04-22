# Python script to install Nym and setup daemon for Artix
import os
import sys
from pathlib import Path

from utils import (
    check_required_apps,
    push_rollback,
    rollback_all,
    run,
)

# --- Defaults (can be overridden via env) ---
OPENRC_INIT_DIR = Path(os.environ.get("OPENRC_INIT_DIR", "/etc/init.d"))
SERVICE_NAME = os.environ.get("SERVICE_NAME", "nym-vpnd")


# install script - this has to run without root
def install_nym(ROLLBACK_STACK):
    # cmd = "trizen -S nym-vpnd-bin nym-vpn-app-bin --noconfirm"
    cmd = "./install.sh nym-vpnd-bin && ./install.sh nym-vpn-app-bin"

    def remove_nym():
        try:
            cmd = "trizen -R nym-vpnd-bin nym-vpn-app-bin --noconfirm"
            run(cmd, shell=True)
        except Exception:
            pass

    ROLLBACK_STACK = push_rollback(remove_nym, ROLLBACK_STACK)

    run(cmd, shell=True)

    return ROLLBACK_STACK


# This function requires root, maybe do it with the run command instead of the built in shutil?
def get_root():
    cmd = "su"
    run(cmd)


def setup_rc(ROLLBACK_STACK):
    nymd_config = (
        "#!/sbin/openrc-run\n"
        'name="nym-vpnd"\n'
        'description="NymVPN daemon"\n'
        'command="/usr/bin/nym-vpnd"\n'
        'command_args="-v run-as-service"\n'
        'pidfile="/run/${RC_SVCNAME}.pid"\n'
        'command_background="yes"\n'
        "depend() {\n"
        "need dbus\n"
        "use net\n"
        "after firewall\n"
        "}\n"
        "start_pre() {\n"
        "checkpath --directory --mode 0755 /run\n"
        "}\n"
        "supervise() {\n"
        'start-stop-daemon --start --exec "${command}" --background --make-pidfile --pidfile "${pidfile}" -- $>\n'
        "}\n"
        "stop() {\n"
        'start-stop-daemon --stop --pidfile "${pidfile}" --retry TERM/5/KILL/5\n'
        'rm -f "${pidfile}"\n'
        "}"
    )
    if not OPENRC_INIT_DIR.exists():
        cmd = f"sudo mkdir {OPENRC_INIT_DIR}"
        run(cmd, shell=True)

    INIT_PATH = OPENRC_INIT_DIR / SERVICE_NAME
    backup_path = None
    init_cmd = ""
    if INIT_PATH.exists():
        backup_path = INIT_PATH.with_suffix(".bak")
        if backup_path.exists():
            cmd = f"sudo rm {backup_path}"
            run(cmd, shell=True)

        init_cmd = f"sudo mv {INIT_PATH} {backup_path}"

        def restore_backup():
            cmd = f"sudo rm {INIT_PATH} && sudo mv {backup_path} {INIT_PATH}"
            run(cmd, shell=True)

        ROLLBACK_STACK = push_rollback(restore_backup, ROLLBACK_STACK)
        run(init_cmd, shell=True)
    else:

        def remove_init():
            cmd = f"sudo rm {INIT_PATH}"
            run(cmd, shell=True)

        ROLLBACK_STACK = push_rollback(remove_init, ROLLBACK_STACK)

    # Write script to init file
    cmd = f"""sudo tee {INIT_PATH} > /dev/null << 'EOF'
    {nymd_config}
    EOF"""

    run(cmd, shell=True)
    print(f"OpenRC service script written to {INIT_PATH}")

    return ROLLBACK_STACK


def start_service(ROLLBACK_STACK):
    # Create Service
    cmd = "sudo rc-update add nym-vpnd default"

    def remove_service():
        cmd = "sudo rc-update del nym-vpnd default"
        run(cmd, shell=True)

    ROLLBACK_STACK = push_rollback(remove_service, ROLLBACK_STACK)
    run(cmd, shell=True)

    # Start service
    cmd = "sudo rc-service nym-vpnd start"

    def stop_service():
        cmd = "sudo rc-service nym-vpnd stop"
        run(cmd)

    ROLLBACK_STACK = push_rollback(stop_service, ROLLBACK_STACK)
    run(cmd)

    return ROLLBACK_STACK


def main():
    ROLLBACK_STACK = []
    required_apps = ["trizen"]

    test_machine = False
    if "--test-machine" in sys.argv:
        required_apps.append("podman")
        required_apps.append("podman-compose")
        test_machine = True
        # TODO: Need to determine if this would allow simulation of nym install

    print("Download and install Nym, get service running for nym-vpnd on OpenRC")

    check_required_apps(required_apps)
    try:
        ROLLBACK_STACK = install_nym(ROLLBACK_STACK)
        ROLLBACK_STACK = setup_rc(ROLLBACK_STACK)
        ROLLBACK_STACK = start_service(ROLLBACK_STACK)
    except Exception as e:
        print("Error encountered during install:", str(e), file=sys.stderr)
        print("Rolling back changes...", file=sys.stderr)
        rollback_all(ROLLBACK_STACK)
        sys.exit(1)


if __name__ == "__main__":
    main()
