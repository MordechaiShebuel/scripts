# Python script to install Nym and setup daemon for Artix


import os
import re
import sys

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from lib.utils import (
    atomic_write,
    check_required_apps,
    ensure_root,
    push_rollback,
    rollback_all,
    run,
    safe_mkdir,
)

print("=== Vaultwarden private server setup (Podman rootless + Bridge Network) ===")

# ================== Configuration ==================
SERVICE_NAME = "vaultwarden"
USER = "vaultwarden"
DATA_DIR = f"/var/lib/{SERVICE_NAME}"
ENV_FILE = f"{DATA_DIR}/env"
NETWORK_NAME = "vaultwarden-bridge"
HOST_IP = "10.0.0.3"  # Your Vendefoul machine IP
PORT_HOST = 8081
DOMAIN = f"http://{HOST_IP}:{PORT_HOST}"

ADMIN_TOKEN_FILE = f"{DATA_DIR}/admin_token"
# ==================================================

# Init script content (single-quoted in shell version; keep consistent)
INIT_SCRIPT = (
    "#!/sbin/openrc-run"
    ""
    'description="Vaultwarden (rootless Podman on bridge network)"'
    'command="/usr/bin/podman"'
    'command_user="vaultwarden"'
    'pidfile="/run/vaultwarden.pid"'
    ""
    "start() {"
    f'    ebegin "Starting Vaultwarden on bridge {NETWORK_NAME}"'
    ""
    '    su -s /bin/sh -c "\\{command} run \\'
    "        --name vaultwarden \\"
    "        --rm \\"
    "        --replace \\"
    "        -d \\"
    f"        --network {NETWORK_NAME} \\"
    f"        --volume {DATA_DIR}/data:/data:z \\"
    f"        --env-file {ENV_FILE} \\"
    f"        -p {HOST_IP}:{PORT_HOST} \\"
    '        vaultwarden/server:latest" \\{command_user}'
    ""
    "    eend \\$?"
    "}"
    ""
    "stop() {"
    '    ebegin "Stopping Vaultwarden"'
    '    su -s /bin/sh -c "\\{command} stop vaultwarden" \\{command_user} 2>/dev/null || true'
    "    eend 0"
    "}"
    "status() {"
    '    su -s /bin/sh -c "\\{command} ps --filter name=vaultwarden" \\{command_user}'
    "}"
)

ROLLBACK_STACK = []


def create_dedicated_user():
    # Create dedicated user (if missing)
    check_user_cmd = (
        'if ! id "{USER}" >/dev/null 2>&1; then'
        "   echo \"→ Creating system user '{USER}' ...\""
        "   if command -v useradd >/dev/null 2>&1; then"
        '       useradd -r -s /sbin/nologin -d "{DATA_DIR}" -m "{USER}"'
        "    else"
        '        adduser -S -H -s /sbin/nologin -D "{USER}"'
        "    fi"
        "fi"
    )

    def remove_user():
        rem_user_cmd = f"sudo userdel {USER}"
        run(rem_user_cmd)

    run(check_user_cmd)
    ROLLBACK_STACK = push_rollback(remove_user, ROLLBACK_STACK)


def setup_namespaces():
    # 3. User namespaces (subuid/subgid)
    namespace_cmd = (
        f'if ! grep -q "^{USER}:" /etc/subuid 2>/dev/null; then'
        'echo "→ Configuring user namespaces ..."'
        f'echo "{USER}:100000:65536" >> /etc/subuid'
        f'echo "{USER}:100000:65536" >> /etc/subgid'
        "fi"
    )

    def reverse_namespace():
        cmd = 'tmp=$(mktemp) && cp /etc/subuid "$tmp" && grep -qxF "{USER}:100000:65536" /etc/subuid || { printf \'%s\n\' "{USER}:100000:65536" >> "$tmp" && mv "$tmp" /etc/subuid; } || rm -f "$tmp"'
        run(cmd)

    ROLLBACK_STACK = push_rollback(reverse_namespace, ROLLBACK_STACK)

    run(namespace_cmd)


def set_permissions():
    # 4. Data directory & permissions
    permissions_cmd = (
        f'mkdir -p "{DATA_DIR}/data"'
        f'chown -R "{USER}:{USER}" "{DATA_DIR}"'
        f'chmod 700 "{DATA_DIR}"'
    )

    run(permissions_cmd)


def generate_token():
    # Generate ADMIN_TOKEN (once)
    generate_token_cmd = (
        f'if [[ ! -f "{ADMIN_TOKEN_FILE}" ]]; then'
        'echo "→ Generating ADMIN_TOKEN ..."'
        f'openssl rand -hex 32 > "{ADMIN_TOKEN_FILE}"'
        f'chmod 600 "{ADMIN_TOKEN_FILE}"'
        "fi"
        f'ADMIN_TOKEN=$(cat "{ADMIN_TOKEN_FILE}")'
    )

    def remove_token():
        cmd = f'rm -f "{ADMIN_TOKEN_FILE}"'
        run(cmd)

    ROLLBACK_STACK = push_rollback(remove_token, ROLLBACK_STACK)

    run(generate_token_cmd)


def env_fix():
    # 5. Environment file
    env_cmd = (
        f'cat > "{ENV_FILE}" <<EOF'
        f"DOMAIN={DOMAIN}"
        f"SIGNUPS_ALLOWED=false"
        "WEBSOCKET_ENABLED=true"
        f"ADMIN_TOKEN={ADMIN_TOKEN}"
        "# Add other settings here (e.g. ROCKET_ADDRESS=0.0.0.0 is default)"
        "EOF"
        f'chown "{USER}:{USER}" "{ENV_FILE}"'
        f'chmod 600 "{ENV_FILE}"'
        ""
        'echo "→ Configuration:"'
        f'echo "   Access URL : {DOMAIN}"'
        f'echo "   Bridge net : {NETWORK_NAME}"'
        f'echo "   Host IP    : {HOST_IP}:{PORT_HOST}"'
    )

    run(env_cmd)


def main():

    required_apps = ["trizen", "podman", "podman-compose"]

    test_machine = False
    if "--test-machine" in sys.argv:
        required_apps.append("podman")
        required_apps.append("podman-compose")
        test_machine = True

    print("Download and install Nym, get service running for nym-vpnd on OpenRC")

    ensure_root()
    check_required_apps(required_apps)
    try:
        create_dedicated_user()
        setup_namespaces()
        set_permissions()
        generate_token()
        env_fix()
    except Exception as e:
        print("Error encountered during install:", str(e), file=sys.stderr)
        print("Rolling back changes...", file=sys.stderr)
        rollback_all(ROLLBACK_STACK)
        sys.exit(1)


if __name__ == "__main__":
    main()
