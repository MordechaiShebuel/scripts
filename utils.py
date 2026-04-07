# utils for setup scripts.

def run(cmd, env=None, capture=False):
    if capture:
        return subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env, text=True)
    else:
        return subprocess.run(cmd, check=True, env=env)

def push_rollback(fn):
    ROLLBACK_STACK.append(fn)

def rollback_all(ROLLBACK_STACK):
    # Run in reverse order, ignore errors
    for fn in reversed(ROLLBACK_STACK):
        try:
            fn()
        except Exception:
            pass
