#!/usr/bin/env bash

# Audio troubleshooting script
rc-service --list | grep pipewire
rc-service pipewire status
rc-service pipewire-pulse status

rc-service pipewire start
rc-update add pipewire default
rc-service pipewire-pulse start
rc-update add pipewire-pulse default

pactl info

sudo pacman -S pipewire pipewire-pulse wireplumber alsa-utils pavucontrol

rc-service wireplumber start
rc-update add wireplumber default

aplay -l
arecord -l

sudo alsa force-reload

sudo modprobe snd_hda_intel

getent group audio
sudo usermod -aG audio $USER

rc-service pulseaudio stop
rc-update del pulseaudio
sudo pacman -Rns pulseaudio

journalctl --user -xeu pipewire
journalctl --user -xeu wireplumber

PIPEWIRE_DEBUG=3 pipewire
wireplumber -v
```)

speaker-test -c2

pactl list short sinks
