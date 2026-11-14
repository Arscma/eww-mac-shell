#!/bin/bash
pgrep -f "title=About This Device" >/dev/null && exit

IMG="$HOME/.config/eww/assets/laptop.png"
IMG_WIDTH=180
YEAR=""
BG="#1e1e1e"
FG="#f2f2f2"
ARCH_URL="https://archlinux.org"
ARCH_SINCE=2002

esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# Nama device
vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)
product=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
name=$(echo "$vendor $product" | esc)

# BIOS YEAR
[ -z "$YEAR" ] && YEAR=$(cat /sys/class/dmi/id/bios_date 2>/dev/null | grep -oE '[0-9]{4}' | tail -1)

# Distro + versi, kernel
distro=$(. /etc/os-release; echo "$NAME ${VERSION_ID:-$BUILD_ID}" | esc)
kernel=$(uname -r | esc)
info="$distro - Linux $kernel - $YEAR"

# CPU
cpu=$(lscpu | awk -F': +' '/Model name/{print $2; exit}' \
  | sed 's/(R)//g; s/(TM)//g; s/ with Radeon Graphics//; s/  */ /g' | esc)

# RAM
ram=$(awk '/MemTotal/{g=$2/1048576; p=1; while(p<g) p*=2; print p " GB"}' /proc/meminfo)

# GPU + VRAM
gpu=$(lspci -mm | awk -F'"' '/VGA|Display/{print $6; exit}' | esc)
vram=""
for f in /sys/class/drm/card*/device/mem_info_vram_total; do
  [ -r "$f" ] && { vram=$(awk '{printf "%d MB", $1/1048576}' "$f"); break; }
done
[ -n "$vram" ] && gpu="$gpu, $vram"

# Storage
disk=$(lsblk -dno NAME,TYPE | awk '$2=="disk" && $1!~/^zram/ {print $1; exit}')
size=$(lsblk -bdno SIZE "/dev/$disk" | awk '{g=$1/1e9; if(g>=1000) printf "%.0f TB", g/1000; else printf "%.0f GB", g}')

# Hyprland
hypr=$(hyprctl version | grep -oP 'v\d+\.\d+\.\d+' | head -1)

tmp=$(mktemp /tmp/about-device.XXXXXX.html)
trap 'rm -f "$tmp"' EXIT

cat > "$tmp" <<EOF
<html><head><meta charset="utf-8"><style>
html,body{margin:0;background:$BG;color:$FG;overflow:hidden;
  font-family:"SF Pro Display","Inter","Cantarell",sans-serif;text-align:center}
body{padding:28px 20px}
img{width:${IMG_WIDTH}px;height:auto;margin-bottom:14px}
.name{font-size:24px;font-weight:700}
.year{font-size:13px;font-weight:300;opacity:.8;margin:2px 0 18px}
.row{font-size:13px;margin:5px 0}
.row b{font-weight:700}
.row span{opacity:.8}
.legal{font-size:10px;opacity:.6;line-height:1.5;margin-top:36px}
.legal a{color:inherit;text-decoration:underline}
</style></head><body>
<img src="file://$IMG">
<div class="name">$name</div>
<div class="year">$info</div>
<div class="row"><b>Chip</b> <span>$cpu</span></div>
<div class="row"><b>Memory</b> <span>$ram</span></div>
<div class="row"><b>Graphics</b> <span>$gpu</span></div>
<div class="row"><b>Storage</b> <span>$size</span></div>
<div class="row"><b>Hyprland</b> <span>$hypr</span></div>
<div class="legal">
<a href="$ARCH_URL">Regulatory Certification</a><br>
™ and © $ARCH_SINCE-$(date +%Y) Arch Linux<br>
All Rights Reserved
</div>
</body></html>
EOF

yad --html --uri="file://$tmp" \
    --title="About This Device" \
    --no-buttons --fixed --center \
    --width=300 --height=440
