# Cron setup

GREEN=$1
NC=$2

if [ ! -e /var/service/cronie ] && [ ! -L /var/service/cronie ]; then
    sudo ln -s /etc/sv/cronie /var/service/cronie
    sleep 1
fi

sudo sv up cronie

for _ in 1 2 3 4 5; do
    if sudo sv status cronie 2>&1 | grep -q 'run:'; then
        echo -e "$GREEN Cronie running properly! $NC"
        break
    fi
    sleep 1
done
