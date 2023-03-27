#!/bin/bash
 
entries="Active Screen Output Area Window"
 
selected=$(printf '%s\n' $entries | wofi --style=$HOME/.config/wofi/style.widgets.css --conf=$HOME/.config/wofi/config.screenshot | awk '{print tolower($1)}')
 
case $selected in
  active)
    $HOME/.config/sway/scripts/grimshot --notify save active;;
  screen)
    $HOME/.config/sway/scripts/grimshot --notify save screen;;
  output)
    $HOME/.config/sway/scripts/grimshot --notify save output;;
  area)
    $HOME/.config/sway/scripts/grimshot --notify save area;;
  window)
    $HOME/.config/sway/scripts/grimshot --notify save window;;
esac
