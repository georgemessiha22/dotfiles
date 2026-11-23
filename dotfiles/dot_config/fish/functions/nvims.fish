set help_msg """Help you choose the Neovim configuration you want to run.
Using the power of `fd` and `fzf` combined.

-c clean the cache and .local setups for selected neovim.
-h Show this help message.
"""


function nvims
    argparse --name=nvims h/help c/clean -- $argv
    if set -q _flag_h
        echo $help_msg
        return
    end

    set selectedVIM $(fd --max-depth 1 --glob 'nvim*' --base-directory $HOME/.config -x echo '{/}' | fzf --prompt="Neovim Configs  > " --height=~50% --layout=reverse --border --exit-0)

    # If I exit fzf without selecting a config, don't open Neovim
    if ! set -q selectedVIM[1]
        echo "No config selected" && return
    end

    if set -q _flag_c
        echo "Cleaning 﫨 $selectedVIM cache only"
        rm -rf $HOME/.local/share/$selectedVIM
        rm -rf $HOME/.local/state/$selectedVIM
        rm -rf $HOME/.cache/$selectedVIM
    else
        # Open Neovim with the selected config
        # echo "Starting NEOVIM $selectedVIM"
        NVIM_APPNAME=$selectedVIM nvim $argv
    end
end
