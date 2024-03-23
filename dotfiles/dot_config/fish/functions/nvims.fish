function nvims
    set config $(fd --max-depth 1 --glob 'nvim*' $HOME/.config | fzf --prompt="Neovim Configs > " --height=~50% --layout=reverse --border --exit-0)

    # If I exit fzf without selecting a config, don't open Neovim
    if set -q $config
        echo "No config selected" && return
    end

    # Open Neovim with the selected config
    NVIM_APPNAME=$(basename $config) nvim $argv
end
