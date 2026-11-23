#!/usr/bin/env bash

# AeroSpace workspaces are not macOS Spaces, so these are plain items.
for sid in 1 2 3 4 5 6 7; do
	sketchybar --add item space."$sid" left \
		--subscribe space."$sid" aerospace_workspace_change aerospace_focus_change \
		--set space."$sid" \
		icon="$sid" \
		label.font="sketchybar-app-font:Regular:16.0" \
		label.padding_right=20 \
		label.y_offset=-1 \
		background.color=0xffa6da95 \
		background.drawing=off \
		icon.color=0xff24273a \
		update_freq=2 \
		click_script="aerospace workspace $sid" \
		script="$PLUGIN_DIR/aerospace_workspace.sh $sid"
done

sketchybar --add item space_separator left \
	--set space_separator icon="" \
	icon.padding_left=4 \
	label.drawing=off \
	background.drawing=off
