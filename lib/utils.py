# utils for setup scripts.
import os
import shutil
import subprocess
import sys
import tempfile
import traceback
from collections.abc import Callable
from pathlib import Path
from typing import List, Optional, Union

RollbackAction = Callable[[], None]


def run(
    cmd: Union[str, list[str]],
    env: Optional[dict[str, str]] = None,
    capture: bool = False,
    shell: bool = False,
) -> Union[None, str]:
    if capture:
        return subprocess.run(
            cmd,
            capture_output=True,
            check=True,
            env=env,
            text=True,
            shell=shell,
        ).stdout
    else:
        try:
            subprocess.run(cmd, check=True, env=env, shell=shell)
        except Exception:
            traceback.print_exc()
            print("Failed to run command", cmd)
            sys.exit(1)
        return None


def push_rollback(
    fn: Callable[[], None], rollback_stack: list[RollbackAction]
) -> list[RollbackAction]:
    rollback_stack.append(fn)
    return rollback_stack


def rollback_all(rollback_stack: List[RollbackAction]):
    # Run in reverse order, ignore errors
    for fn in reversed(rollback_stack):
        try:
            fn()
        except Exception:
            pass


def atomic_write(path: Path, data: str, mode=0o755, encoding="utf-8"):
    fd, fname = tempfile.mkstemp(dir=str(path.parent))
    td = Path(fname)
    try:
        # close the low-level fd; we'll write via Path to control encoding
        os.close(fd)
        td.write_text(data, encoding=encoding)
        os.chmod(str(td), mode)
        os.replace(str(td), str(path))
    finally:
        if td.exists():
            try:
                td.unlink()
            except Exception:
                pass


def safe_mkdir(p: Path):
    created = []
    if not p.exists():
        p.mkdir(parents=True, exist_ok=True)
        created.append(p)
    return created


def ensure_root():
    if os.geteuid() != 0:
        print("Run as root or via sudo.", file=sys.stderr)
        sys.exit(1)


def check_required_apps(apps):
    for app in apps:
        if shutil.which(app) is None:
            cmd = f"./../system_scripts/install.sh {app}"
            run(cmd)


def install_apps(in_cmd, apps):
    for app in apps:
        if not app_installed(app):
            cmd = f"{in_cmd} {app}"
            run(cmd, shell=True)


def app_installed(app):
    cmd = f"if [[ $(pamac list --installed --quiet | grep {app}) == {app} ]]; then echo 'installed'; else echo 'not installed'; fi"
    try:
        installed = run(cmd, shell=True, capture=True)
        if str(installed).strip() == "installed":
            return True
        return False
    except Exception:
        return False


def setup_test_machine(rollback_stack, test_machine=False):
    # If test_machine requested, init/start podman machine
    if test_machine:
        try:
            run(["podman", "machine", "init"])
        except subprocess.CalledProcessError:
            # ignore if already exists
            pass
        run(["podman", "machine", "start"])
        # running podman commands will use the machine automatically in many setups;
        # if not, user can use `podman machine ssh` manually for full isolation.

        # For rollback: stop machine if we started it here.
        def stop_machine():
            try:
                run(["podman", "machine", "stop"])
            except Exception:
                pass

        rollback_stack = push_rollback(stop_machine, rollback_stack)


def detect_distro():
    """Detect if the system is Arch-based or Debian-based."""
    # Check for Arch-based systems
    if Path("/etc/arch-release").exists():
        return "arch"
    # Check for Debian-based systems
    if Path("/etc/debian_version").exists():
        return "debian"
    # Fallback: check os-release
    os_release = Path("/etc/os-release")
    if os_release.exists():
        content = os_release.read_text()
        if "arch" in content.lower() or "artix" in content.lower():
            return "arch"
        if (
            "debian" in content.lower()
            or "ubuntu" in content.lower()
            or "linuxmint" in content.lower()
            or "Vendefoul" in content.lower()
        ):
            return "debian"
    return "unknown"


def check_service(service: str) -> bool:
    cmd = f"sudo rc-service {service} status"
    try:
        status = run(cmd, shell=True, capture=True)
        if "started" in str(status):
            return True
        return False
    except Exception:
        return False


def check_apps(pkgs: list[str]) -> bool:
    appcheck = 0
    for pkg in pkgs:
        try:
            if app_installed(pkg):
                appcheck = appcheck + 1
        except Exception:
            traceback.print_exc()
            pass
    return appcheck == len(pkgs)


def setup_rc_service(
    rollback_stack: list[RollbackAction],
    OPENRC_INIT_DIR: Path,
    SERVICE_NAME: str,
    RC_CONFIG: str,
) -> list[RollbackAction]:

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

        rollback_stack = push_rollback(restore_backup, rollback_stack)
        run(init_cmd, shell=True)
    else:

        def remove_init():
            cmd = f"sudo rm {INIT_PATH}"
            run(cmd, shell=True)

        rollback_stack = push_rollback(remove_init, rollback_stack)

    # Write script to init file
    cmd = f"""sudo tee {INIT_PATH} > /dev/null << 'EOF'
{RC_CONFIG}
EOF"""

    run(cmd, shell=True)
    print(f"OpenRC service script written to {INIT_PATH}")

    return rollback_stack


def install_required_apps(
    rollback_stack: list[RollbackAction], pkgs: list[str], distro: str
) -> list[RollbackAction]:
    installer = "trizen -S" if distro == "arch" else "apt-get install -y"
    remover = "trizen -R" if distro == "arch" else "apt-get remove -y"

    def remove_nym():
        try:
            cmd = f"{remover} "

            for pkg in pkgs:
                cmd += f"{pkg} "
            run(cmd, shell=True)
        except Exception:
            pass

    rollback_stack = push_rollback(remove_nym, rollback_stack)

    install_apps(installer, pkgs)

    return rollback_stack


def start_service(
    rollback_stack: list[RollbackAction], SERVICE_NAME: str, OPENRC_INIT_DIR: Path
) -> list[RollbackAction]:
    # Set service file to be +X

    INIT_PATH = OPENRC_INIT_DIR / SERVICE_NAME
    cmd = f"sudo chmod +x {INIT_PATH}"
    run(cmd, shell=True)

    cmd = f"sudo rc-update add {SERVICE_NAME} default"

    def remove_service():
        cmd = f"sudo rc-update del {INIT_PATH} default"
        run(cmd, shell=True)

    rollback_stack = push_rollback(remove_service, rollback_stack)
    run(cmd, shell=True)

    # Start service
    cmd = f"sudo rc-service {SERVICE_NAME} start"

    def stop_service():
        cmd = f"sudo rc-service {SERVICE_NAME} stop"
        run(cmd, shell=True)

    rollback_stack = push_rollback(stop_service, rollback_stack)
    run(cmd, shell=True)

    return rollback_stack


def set_ownership(
    path: Path, user: int, group: int, rollback_stack: list[RollbackAction] = []
) -> list[RollbackAction]:
    def restore_ownership():
        os.chown(str(path), user, group)

    rollback_stack = push_rollback(restore_ownership, rollback_stack)
    os.chown(str(path), user, group)

    return rollback_stack


def set_ownership_recursive(
    path: Path, user: int, group: int, rollback_stack: list[RollbackAction] = []
) -> list[RollbackAction]:

    for p in path.rglob("*"):
        rollback_stack = set_ownership(p, user, group, rollback_stack)

    return rollback_stack


def set_ownership_array(
    paths: list[Path], user: int, group: int, rollback_stack: list[RollbackAction] = []
) -> list[RollbackAction]:
    for p in paths:
        rollback_stack = set_ownership(p, user, group, rollback_stack)

    return rollback_stack


def pull_image(
    podman_cmd: str, image: str, rollback_stack: list[RollbackAction] = []
) -> list[RollbackAction]:

    def rollback():
        run(f"{podman_cmd} rmi {image}")

    rollback_stack = push_rollback(rollback, rollback_stack)

    run(f"{podman_cmd} pull {image}")

    return rollback_stack


def create_podman_container(
    podman_cmd: str,
    container_name: str,
    jellyfin_http_port: str,
    jellyfin_https_port: str,
    config_dir: str,
    cache_dir: str,
    media_dir: str,
    image: str,
    rollback_stack: list[RollbackAction] = [],
) -> list[RollbackAction]:
    exists = run(f"{str(podman_cmd)} container exists {container_name}")

    if exists and "exists" in exists:
        print(f"Container '{container_name}' already exists.")
    else:

        def remove_container() -> None:
            run([str(podman_cmd), "rm", "-f", container_name])

        rollback_stack = push_rollback(remove_container, rollback_stack)

        print(f"Creating container '{container_name}' with port mappings (LAN-only).")
        run(
            [
                str(podman_cmd),
                "create",
                "--name",
                container_name,
                "--restart=always",
                "-p",
                f"{jellyfin_http_port}:8096/tcp",
                "-p",
                f"{jellyfin_https_port}:8920/tcp",
                "-v",
                f"{config_dir}:/config",
                "-v",
                f"{cache_dir}:/cache",
                "-v",
                f"{media_dir}:/media:ro",
                image,
            ]
        )
    return rollback_stack


def setup_directories(
    DIRS: list[Path],
    rollback_stack: list[RollbackAction],
) -> list[RollbackAction]:
    created_paths = []
    for p in DIRS:
        created = safe_mkdir(p)
        if created:
            created_paths.extend(created)
            # rollback: remove the directory only if it is empty to avoid deleting user data
            rollback_stack = push_rollback(
                lambda p=p: (
                    None
                    if not (p.exists() and not any(p.iterdir()))
                    else (p.rmdir() or None)
                ),
                rollback_stack,
            )

    return rollback_stack
