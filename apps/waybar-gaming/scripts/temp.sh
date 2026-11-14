#!/usr/bin/env bash
for h in /sys/class/hwmon/hwmon*; do
  if [ "$(cat "$h/name" 2>/dev/null)" = "$1" ]; then
    echo $(( $(cat "$h/temp1_input") / 1000 ))
    exit 0
  fi
done
echo 0
