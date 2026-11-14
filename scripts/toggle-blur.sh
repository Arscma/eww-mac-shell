#!/usr/bin/env bash
f="$HOME/.config/eww/scripts/status/.blur-mode"
cur=$(hyprctl getoption decoration:blur:enabled -j | jq -r '.bool')

if [[ "$cur" == "false" ]]; then
    hyprctl eval 'hl.config({ decoration = { blur = { enabled = true }, active_opacity = 0.65, inactive_opacity = 0.55 } })'
    hyprctl eval 'hl.plugin.hyprglass.config({ enabled = true })'
    echo on > "$f"
else
    hyprctl reload
    echo off > "$f"
fi
