#!/bin/bash
KVER="6.18.5-1-cachyos"
SRC="/usr/lib/modules/$KVER/vmlinuz"
DST="/boot/vmlinuz-$KVER"
INITRAMFS="/boot/initramfs-$KVER.img"

[ -f "$SRC" ] || {
    echo "Missing kernel: $SRC" >&2
    exit 1
}

sudo cp -- "$SRC" "$DST" &&
sudo depmod "$KVER" &&
sudo dracut --force "$INITRAMFS" "$KVER" &&
sudo test -s "$INITRAMFS" &&
sudo grub-mkconfig -o /boot/grub/grub.cfg &&
sudo grep -Fq "$KVER" /boot/grub/grub.cfg ||
{
    echo "Kernel workaround failed." >&2
    exit 1
}
