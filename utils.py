# utils for setup scripts.
import subprocess
import os
import sys

def run(cmd, env=None, capture=False):
    if capture:
        return subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env, text=True)
    else:
        return subprocess.run(cmd, check=True, env=env)

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

def atomic_write(path: Path, data: str, mode=0o755):
    td = Path(tempfile.mkstemp(dir=str(path.parent))[1])
    try:
        td.write_text(data)
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
            cmd = f'pacman -S {app}'
            run(cmd)
