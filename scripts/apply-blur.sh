#!/usr/bin/env bash
[ "$(cat "$HOME/.config/eww/scripts/status/.blur-mode" 2>/dev/null)" = on ] || exit 0
hyprctl eval 'hl.config({ decoration = { blur = { enabled = true }, active_opacity = 0.65, inactive_opacity = 0.55 } })'
hyprctl eval 'hl.plugin.hyprglass.config({ enabled = true })'
