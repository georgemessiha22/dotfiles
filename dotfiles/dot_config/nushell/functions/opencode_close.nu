# opencode_close.nu — close & delete all opencode sessions
# Ported from fish: ~/.config/fish/conf.d/opencode.fish

export def main [] {
    ^opencode session --format=json list
    | from json
    | each {|s| ^opencode session delete $s.id }
    | ignore
}
