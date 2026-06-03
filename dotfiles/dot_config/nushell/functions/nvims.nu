# nvims.nu — choose a Neovim configuration via fd + fzf
# Ported from fish: ~/.config/fish/functions/nvims.fish

export def main [
    --clean (-c)   # clean cache/state/data for selected nvim config
    --help (-h)    # show help and exit
    ...args        # passed through to nvim
] {
    if $help {
        print "Help you choose the Neovim configuration you want to run."
        print "Using the power of `fd` and `fzf` combined."
        print ""
        print "-c clean the cache and .local setups for selected neovim."
        print "-h Show this help message."
        return
    }

    let selected = (
        ^fd --max-depth 1 --glob 'nvim*' --base-directory $"($env.HOME)/.config"
        | ^fzf --prompt "Neovim Configs  > " --height "~50%" --layout reverse --border --exit-0
        | str trim
    )

    if ($selected | is-empty) {
        print "No config selected"
        return
    }

    if $clean {
        print $"Cleaning ($selected) cache only"
        rm -rf $"($env.HOME)/.local/share/($selected)"
        rm -rf $"($env.HOME)/.local/state/($selected)"
        rm -rf $"($env.HOME)/.cache/($selected)"
    } else {
        with-env { NVIM_APPNAME: $selected } {
            ^nvim ...$args
        }
    }
}
