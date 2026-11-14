#!/usr/bin/env bash
# Gamemode Toggle

STATE_FILE="/tmp/hypr_gamemode_state"
WB_CFG="$HOME/.config/eww/apps/waybar-gaming/config.jsonc"
WB_CSS="$HOME/.config/eww/apps/waybar-gaming/style.css"
PDIR="/var/cache/hyprpm/$USER"
PLUGINS=(
    "$PDIR/HyprGlass/hyprglass.so"
    "$PDIR/dynamic-cursors/dynamic-cursors.so"
    "$PDIR/hyprland-plugins/hyprbars.so"
)

notify() {
    command -v notify-send >/dev/null &&
        notify-send "Game Mode" "$1" -u low -t 1500
}

quiet() { "$@" >/dev/null 2>&1; }

gamemode_on() {
    setsid -f gamemoderun sleep infinity >/dev/null 2>&1
    sleep 0.3
    pgrep -nx sleep > "$STATE_FILE"
}

gamemode_off() {
    local pid
    pid=$(cat "$STATE_FILE" 2>/dev/null)
    [[ "$pid" =~ ^[0-9]+$ ]] && quiet kill "$pid"
}

if [ ! -f "$STATE_FILE" ]; then
    # ================= ON =================
    notify "Activated (Maximum Performance)"

    gamemode_on

    for p in "${PLUGINS[@]}"; do quiet hyprctl plugin unload "$p"; done
    sleep 0.5

    hyprctl eval '
        hl.config({
            general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
            decoration = {
                rounding = 0,
                active_opacity = 1.0,
                inactive_opacity = 1.0,
                shadow = { enabled = false },
                blur = { enabled = false },
            },
            animations = { enabled = false },
        })
    '

    quiet eww kill || pkill -x eww
    sleep 0.3
    setsid -f waybar -c "$WB_CFG" -s "$WB_CSS" >/dev/null 2>&1
else
    # ================= OFF =================
    gamemode_off
    rm -f "$STATE_FILE"

    quiet pkill -f "waybar -c $WB_CFG"

    quiet hyprpm reload -n
    sleep 1
    hyprctl reload

    notify "Deactivated (Normal Rice)"

    setsid -f "$HOME/.config/eww/scripts/startandrestart.sh" >/dev/null 2>&1
fi
