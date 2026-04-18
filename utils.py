# utils for setup scripts.
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def run(cmd, env=None, capture=False, shell=False):
    if capture:
        return subprocess.run(
            cmd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            text=True,
            shell=shell,
        )
    else:
        return subprocess.run(cmd, check=True, env=env, shell=shell)


def push_rollback(fn, ROLLBACK_STACK):
    ROLLBACK_STACK.append(fn)
    return ROLLBACK_STACK


def rollback_all(ROLLBACK_STACK):
    # Run in reverse order, ignore errors
    for fn in reversed(ROLLBACK_STACK):
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
            cmd = f"./install.sh {app}"
            run(cmd)


def setup_test_machine(ROLLBACK_STACK, test_machine=False):
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

        ROLLBACK_STACK = push_rollback(stop_machine, ROLLBACK_STACK)
