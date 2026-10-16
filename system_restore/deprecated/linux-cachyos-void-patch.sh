#!/bin/bash
KVER="6.18.5-1-cachyos"
SRC_K="/usr/lib/modules/$KVER/vmlinuz"
SRC_C="/usr/lib/modules/$KVER/.config"
DST_K="/boot/vmlinuz-$KVER"
DST_C="/boot/config-$KVER"
INITRAMFS="/boot/initramfs-$KVER.img"

[ -f "$SRC" ] || {
    echo "Missing kernel: $SRC" >&2
    exit 1
}

sudo cp -- "$SRC_K" "$DST_K" &&
sudo cp -- "$SRC_C" "$DST_C" &&
sudo depmod "$KVER" &&
sudo dracut --force "$INITRAMFS" "$KVER" &&
sudo test -s "$INITRAMFS" &&
sudo grub-mkconfig -o /boot/grub/grub.cfg &&
sudo grep -Fq "$KVER" /boot/grub/grub.cfg ||
{
    echo "Kernel workaround failed." >&2
    exit 1
}
