#!/usr/bin/env bash

DEVICES="$(system_profiler SPBluetoothDataType -json -detailLevel basic 2>/dev/null | jq '.SPBluetoothDataType' | jq '.[0]' | jq '.device_title' | jq -r '.[] | keys[] as $k | "\($k) \(.[$k] | .device_isconnected) \(.[$k] | .device_minorClassOfDevice_string)"' | grep 'attrib_Yes' | grep 'Headphones')"

if [ "$DEVICES" = "" ]; then
  sketchybar -m --set $NAME drawing=off
else
  sketchybar -m --set $NAME drawing=on
fi
