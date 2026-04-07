# Python script to install Nym and setup daemon for Artix

# install script
# trizen -S nym-vpnd-bin nym-vpn-app-bin

# Create config for OpenRC
nymd_config = ("#!/sbin/openrc-run"
"name=\"nym-vpnd\""
"description=\"NymVPN daemon\""
"command=\"/usr/bin/nym-vpnd\""
"command_args=\"-v run-as-service\""
"pidfile=\"/run/\$\{RC_SVCNAME\}.pid\""
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
"start-stop-daemon --start --exec \"$\{command\}\" --background --make-pidfile --pidfile \"$\{pidfile\}\" -- $>"
"}"

"stop() {"
"start-stop-daemon --stop --pidfile \"$\{pidfile\}\" --retry TERM/5/KILL/5"
"rm -f \"$\{pidfile\}\""
"}")

# Define init.d file
init_file = "/etc/init.d/nym-vpnd"

# Save output to init.d file

# Start services
# sudo rc-update add nym-vpnd default
# sudo rc-service nym-vpnd start
