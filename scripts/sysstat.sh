#!/usr/bin/env bash
DISK=nvme0n1
PEAK=/tmp/eww-sysstat-peak
STAMP=/tmp/eww-sysstat-stamp
now=$(date +%s); last=$(cat "$STAMP" 2>/dev/null || echo 0)
(( now - last > 3 )) && rm -f "$PEAK"
echo "$now" > "$STAMP"

hw() { local h; for h in /sys/class/hwmon/hwmon*; do [[ $(<"$h/name") == "$1" ]] && { echo "$h"; return; }; done; }
CPUT=$(hw k10temp)
GPUT=$(hw amdgpu)
for d in /sys/class/drm/card*/device; do [[ -e $d/gpu_busy_percent ]] && GD=$d && break; done

read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat
d1=$(awk -v d="$DISK" '$3==d{print $13}' /proc/diskstats)
t1=$(date +%s%N)
sleep 0.4
# sampel 2
read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat
d2=$(awk -v d="$DISK" '$3==d{print $13}' /proc/diskstats)
t2=$(date +%s%N)

# CPU %
user=$(( (u2-u1)+(n2-n1) ))
sys=$(( (s2-s1)+(q2-q1)+(sq2-sq1)+(st2-st1) ))
idle=$(( (i2-i1)+(w2-w1) ))
tot=$(( user+sys+idle )); (( tot==0 )) && tot=1
cu=$(( 100*user/tot )); cs=$(( 100*sys/tot )); ci=$(( 100-cu-cs ))

cpu_name=$(sed -n '/model name/{s/.*: //;s/ with Radeon Graphics//;p;q}' /proc/cpuinfo)
cpu_temp=$(( $(<"$CPUT/temp1_input") / 1000 ))

# top 5 RAM
mt=$(awk '/MemTotal/{print $2}' /proc/meminfo)
procs=$(ps -eo rss=,comm= | awk '{r=$1;$1="";sub(/^ +/,"");a[$0]+=r} END{for(k in a)printf "%s\t%d\n",k,a[k]}' \
  | sort -t$'\t' -k2 -nr | head -5 \
  | awk -F'\t' -v mt="$mt" '
    function fmt(k){return k>=1048576?sprintf("%.1f GB",k/1048576):sprintf("%d MB",k/1024)}
    BEGIN{printf "["}
    {gsub(/["\\]/,"",$1); printf "%s{\"name\":\"%s\",\"size\":\"%s\",\"pct\":\"%.1f\"}",(NR>1?",":""),$1,fmt($2),$2*100/mt}
    END{printf "]"}')

ram_txt=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%.1f / %.1f GB",(t-a)/1048576,t/1048576}' /proc/meminfo)

# GPU
gpu_temp=$(( $(<"$GPUT/temp1_input") / 1000 ))
sclk=$(awk '/\*/{gsub(/[^0-9]/,"",$2);print $2}' "$GD/pp_dpm_sclk")
mclk=$(awk '/\*/{gsub(/[^0-9]/,"",$2);printf "%.2f",$2/1000}' "$GD/pp_dpm_mclk")
vu=$(<"$GD/mem_info_vram_used"); vt=$(<"$GD/mem_info_vram_total")
vp=$(( 100*vu/vt )); vu_mb=$(( vu/1048576 )); vt_mb=$(( vt/1048576 ))
gbusy=$(<"$GD/gpu_busy_percent")

# Storage I/O busy + peak
ms=$(( (t2-t1)/1000000 )); (( ms<1 )) && ms=1
dl=$(( 100*(d2-d1)/ms )); (( dl>100 )) && dl=100; (( dl<0 )) && dl=0
pk=$(cat "$PEAK" 2>/dev/null || echo 0)
if (( dl > pk )); then pk=$dl; echo "$pk" > "$PEAK"; fi

# uptime
up=$(awk '{s=int($1);d=int(s/86400);h=int(s%86400/3600);m=int(s%3600/60);
  if(d>0)printf "%dd %dh %dm",d,h,m; else if(h>0)printf "%dh %dm",h,m; else printf "%dm",m}' /proc/uptime)


printf '{"cpu_name":"%s","cpu_user":%d,"cpu_sys":%d,"cpu_idle":%d,"cpu_temp":%d,"ram_txt":"%s","procs":%s,"gpu_temp":%d,"gpu_core":%s,"gpu_mem_clk":"%s","vram_p":%d,"vram_txt":"%d/%d MB","gpu_busy":%d,"disk":%d,"disk_peak":%d,"uptime":"%s"}\n' \
  "$cpu_name" "$cu" "$cs" "$ci" "$cpu_temp" "$ram_txt" "$procs" "$gpu_temp" "$sclk" "$mclk" "$vp" "$vu_mb" "$vt_mb" "$gbusy" "$dl" "$pk" "$up"
