#!/usr/bin/env bash
EWW_DIR="$HOME/.config/eww"
SCSS="$EWW_DIR/eww.scss"
STATE_FILE="$EWW_DIR/scripts/status/.theme-mode"
YUCKS=(
    "$EWW_DIR/eww.yuck"
    "$EWW_DIR/control_center.yuck"
    "$EWW_DIR/dock.yuck"
)

CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "dark")

if [[ "$CURRENT" == "dark" ]]; then
    MODE="light"
    FG="#000000"
    FG_MUTED="#000000"
    FG_SILENT="#000000"
    BAR_COLOR="#ffffff47"; BAR_TEXT="#000000"
    ICON_THEME="WhiteSur-light"
    BATTERY_THEME="WhiteSur-light"
    BG="rgba(225, 225, 225, 0.09)"
    CLOCK_FACE="#2a2a2c"; CLOCK_HAND="#ffffff"; CLOCK_TICK="#8e8e93"; CLOCK_SEC="#ff9f0a"
else
    MODE="dark"
    FG="#FFFFFF"
    FG_MUTED="#D0D0D0"
    FG_SILENT="#FFFFFF"
    BAR_COLOR="#363a39bf"; BAR_TEXT="#ffffffff"
    ICON_THEME="WhiteSur-dark"
    BATTERY_THEME="WhiteSur"
    BG="transparent"
    CLOCK_FACE="#ffffff"; CLOCK_HAND="#1c1c1e"; CLOCK_TICK="#8e8e93"; CLOCK_SEC="#ff9f0a"
fi

for FILE in "${YUCKS[@]}"; do
    [[ -f "$FILE" ]] || continue
    sed -i -E \
        -e "s#/usr/share/icons/WhiteSur(-dark|-light)?/status/32/battery-#@@BAT@@battery-#g" \
        -e "s#/usr/share/icons/WhiteSur(-dark|-light)?/#/usr/share/icons/${ICON_THEME}/#g" \
        -e "s#@@BAT@@#/usr/share/icons/${BATTERY_THEME}/status/32/#g" \
        "$FILE"
done

sed -i \
    -e "s|^\$color-fg:.*|\$color-fg: ${FG};|" \
    -e "s|^\$color-fg-muted:.*|\$color-fg-muted: ${FG_MUTED};|" \
    -e "s|^\$color-fg-silent:.*|\$color-fg-silent: ${FG_SILENT};|" \
    -e "s|^\$clock-face:.*|\$clock-face: ${CLOCK_FACE};|" \
    -e "s|^\$clock-hand:.*|\$clock-hand: ${CLOCK_HAND};|" \
    -e "s|^\$clock-tick:.*|\$clock-tick: ${CLOCK_TICK};|" \
    -e "s|^\$clock-sec:.*|\$clock-sec: ${CLOCK_SEC};|" \
    "$SCSS"

printf '%s\n' "$MODE" > "$STATE_FILE"

if [[ "$MODE" == "dark" ]]; then DRAWER_MODE="light"; else DRAWER_MODE="dark"; fi
ln -sfn "drawer-${DRAWER_MODE}.css" "$HOME/.config/eww/apps/nwg-drawer/drawer.css"
ln -sfn "style-${MODE}.css" "$HOME/.config/eww/apps/swaync/style.css"
swaync-client -rs &>/dev/null || true

hyprctl eval "hl.config({ plugin = { hyprbars = { bar_color = \"${BAR_COLOR}\", [\"col.text\"] = \"${BAR_TEXT}\" } } })" >/dev/null 2>&1 || true
   for addr in $(hyprctl clients -j | jq -r '.[] | select(.mapped) | .address'); do
       hyprctl dispatch "hl.dsp.window.resize({ x = 1, y = 0, relative = true, window = \"address:${addr}\" })" >/dev/null 2>&1
       hyprctl dispatch "hl.dsp.window.resize({ x = -1, y = 0, relative = true, window = \"address:${addr}\" })" >/dev/null 2>&1
   done

eww reload >/dev/null 2>&1 || true
