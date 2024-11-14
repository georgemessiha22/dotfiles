#!/usr/bin/env zsh

ICON_PADDING_RIGHT=5

case $INFO in
    "Finder")
        ICON_PADDING_RIGHT=3
        ICON=
        ;;
    "Arc")
        ICON_PADDING_RIGHT=5
        ICON=󰞍
        ;;
    "Code")
        ICON_PADDING_RIGHT=4
        ICON=󰨞
        ;;
    "Calendar")
        ICON_PADDING_RIGHT=3
        ICON=
        ;;
    "Discord")
        ICON=󰙯
        ;;
    "FaceTime")
        ICON_PADDING_RIGHT=5
        ICON=
        ;;
    "Finder")
        ICON=
        ;;
    "Google Chrome")
        ICON_PADDING_RIGHT=7
        ICON=
        ;;
    "IINA")
        ICON_PADDING_RIGHT=4
        ICON=󰕼
        ;;
    "kitty")
        ICON=󰄛
        ;;
    "Messages")
        ICON=󰍦
        ;;
    "Notion")
        ICON_PADDING_RIGHT=6
        ICON=󰈄
        ;;
    "Preview")
        ICON_PADDING_RIGHT=3
        ICON=
        ;;
    "PS Remote Play")
        ICON_PADDING_RIGHT=3
        ICON=
        ;;
    "Spotify")
        ICON=
        ;;
    "TextEdit")
        ICON_PADDING_RIGHT=4
        ICON=
        ;;
    "Transmission")
        ICON_PADDING_RIGHT=3
        ICON=󰶘
        ;;
    "Alacritty")
        ICON_PADDING_RIGHT=3
        ICON=
        ;;
    "neovim")
        ICON_PADDING_RIGHT=3
        ICON=
        ;;
    "Brave Browser")
        ICON_PADDING_RIGHT=2
        ICON=🦁
        ;;
		"Slack")
				ICON_PADDING_RIGHT=2
				ICON=󰒱
				;;
    *)
        ICON=
        ;;
esac
#
#
ICON=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$INFO") "

sketchybar --set $NAME icon=$ICON icon.padding_right=$ICON_PADDING_RIGHT icon.font="sketchybar-app-font:Regular:16.0"
sketchybar --set $NAME.name label="$INFO"

