#!/usr/bin/env bash
cd "$HOME/.config/eww" || exit 1

lock="${XDG_RUNTIME_DIR:-/tmp}/eww-startandrestart.lock"
if [ "${FLOCKER}" != "$0" ]; then
    pids=$(fuser "$lock" 2>/dev/null)
    [ -n "$pids" ] && ps -o comm= -p $pids 2>/dev/null | grep -qvE '^(flock|startandrestart.sh)$' && rm -f "$lock"
fi

[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -eno "${XDG_RUNTIME_DIR:-/tmp}/eww-startandrestart.lock" "$0" "$@"
pgrep -x waybar >/dev/null && exit 0

eww kill >/dev/null 2>&1
pkill -x eww >/dev/null 2>&1
for i in $(seq 1 30); do
    pgrep -x eww >/dev/null || break
    sleep 0.1
done
pkill -9 -x eww >/dev/null 2>&1
pkill -f "^(bash|python3) [.]/scripts/bin/" >/dev/null 2>&1; sleep 0.3
pkill -f "socat.*socket2.sock" >/dev/null 2>&1

eww daemon 3>&- 9>&- >/dev/null 2>&1
# eww daemon 9>&- >/dev/null 2>&1
for i in $(seq 1 50); do
    eww list-windows >/dev/null 2>&1 && break
    sleep 0.1
done

eww list-windows >/dev/null 2>&1 || exit 1
wins="panel control_center panel_shadow dock dock_open_area dock_preview menu sysstat fetch help_menu"
d="$HOME/.cache/eww-dt"
[ "$(cat "$d/clock_on" 2>/dev/null)" = true ] && wins="$wins clock_$(cat "$d/clock_mode" 2>/dev/null || echo digital)"
for w in calendar weather; do
    [ "$(cat "$d/${w}_on" 2>/dev/null)" = true ] && wins="$wins ${w}_widget"
done
if ! { timeout -s KILL 10 eww open-many $wins && [ "$(pgrep -xc eww)" = 1 ]; }; then
    [ "${RETRY:-0}" -lt 2 ] && exec env RETRY=$(( ${RETRY:-0} + 1 )) "$0"
    echo "open-many gagal setelah retry" >&2; exit 1
fi

setsid -f sh -c 'u="$(./scripts/bin/update-check)"; eww list-windows >/dev/null 2>&1 && eww update updates="$u"' 3>&- 9>&- >/dev/null 2>&1
