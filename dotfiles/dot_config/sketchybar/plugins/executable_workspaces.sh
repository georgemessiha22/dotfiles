#!/usr/bin/env bash

SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")
for sid in "${SPACE_ICONS[@]}"; do
	sketchybar --add space space."$sid" left \
		--set space."$sid" space="$sid" \
		icon="$sid" \
		label.font="sketchybar-app-font:Regular:16.0" \
		label.padding_right=20 \
		label.y_offset=-1 \
		background.color=0xfff5a97f \
		icon.color=0xff24273a \
		script="$PLUGIN_DIR/space.sh"
	# sid="$(($i + 1))"
	# space=(
	# 	space="$sid"
	# 	icon="${SPACE_ICONS[i]}"
	# 	# icon="$INFO"
	# 	icon.padding_left=7
	# 	icon.padding_right=7
	# 	background.color=0xfff5a97f
	# 	icon.color=0xff24273a
	# 	# background.color=0x40ffffff
	# 	background.corner_radius=5
	# 	background.height=25
	# 	label.drawing=off
	# 	script="$PLUGIN_DIR/space.sh"
	# 	click_script="yabai -m space --focus $sid"
	# )
	# sketchybar --add space space."$sid" left --set space."$sid" "${space[@]}"
done

sketchybar --add item space_separator left \
	--set space_separator icon="" \
	icon.padding_left=4 \
	label.drawing=off \
	background.drawing=off \
	script="$PLUGIN_DIR/space_windows.sh" \
	--subscribe space_separator space_windows_change
