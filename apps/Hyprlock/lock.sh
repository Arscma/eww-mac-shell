#!/usr/bin/env bash
pidof hyprlock >/dev/null && exit 0

PHOTO_DIR="$HOME/.config/eww/apps/Hyprlock/profile-photos"
OUTPUT="$HOME/.config/eww/apps/Hyprlock/profile.jpg"

photo=$(find "$PHOTO_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | shuf -n 1)

[[ -n $photo ]] && cp -- "$photo" "$OUTPUT"

exec hyprlock -c "$HOME/.config/eww/apps/Hyprlock/hyprlock.conf"
