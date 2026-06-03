# zellij_kill.nu — kill and delete all zellij sessions
# Ported from fish: ~/.config/fish/conf.d/zellij.fish

export def main [] {
    ^zellij kill-all-sessions
    ^zellij delete-all-sessions
}
