#!/usr/bin/env bash
os=$(. /etc/os-release; echo "$PRETTY_NAME $(uname -m)")

v=$(hyprctl version -j 2>/dev/null | jq -r '.tag // empty' | sed 's/^v//')
[ -n "$v" ] && wm="Hyprland $v" || wm="Hyprland"

d=/sys/devices/virtual/dmi/id
user=$(id -un)

kernel=$(uname -r)

sh_bin=$(getent passwd "$USER" | cut -d: -f7)
sh_name=$(basename "$sh_bin")
sh_ver=$("$sh_bin" --version 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)
shell="$sh_name $sh_ver"

parts=()
n=$(pacman -Qq 2>/dev/null | wc -l); (( n > 0 )) && parts+=("$n (pacman)")
if command -v flatpak >/dev/null; then
  n=$(flatpak list --app 2>/dev/null | wc -l); (( n > 0 )) && parts+=("$n (flatpak)")
fi
pkgs=$(printf '%s, ' "${parts[@]}"); pkgs=${pkgs%, }

read -r used size pct < <(df -h --output=used,size,pcent / | tail -1)
disk="$used / $size ($pct)"

jq -nc --arg os "$os" --arg wm "$wm" --arg user "$user" --arg kernel "$kernel" \
  --arg shell "$shell" --arg pkgs "$pkgs" --arg disk "$disk" \
  '{os:$os,wm:$wm,user:$user,kernel:$kernel,shell:$shell,pkgs:$pkgs,disk:$disk}'
