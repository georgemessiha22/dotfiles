# aliases.nu — ported from fish 000-config.fish
# Linux-only / pacman aliases skipped (grubup, fixpacman, rmpkg, upd, cleanup, jctl, rip, gitpkg, hw, big)

# Navigation
alias ..      = cd ..
alias ...     = cd ../..
alias ....    = cd ../../..
alias .....   = cd ../../../..
alias ......  = cd ../../../../..

# Colors / coreutils
alias ip      = ip -color
alias grep    = grep --color=auto
alias fgrep   = grep -F --color=auto
alias egrep   = grep -E --color=auto
alias dir     = dir --color=auto
alias vdir    = vdir --color=auto

# Quality of life
alias tarnow  = tar -acf
alias untar   = tar -xvf
alias wget    = wget -c
alias cat     = bat --style=grid,snip,header-filename,header-filesize

# Editor
alias edit    = nvim
alias e       = nvim

# Configs
alias zshconfig = nvim ~/.zshrc
alias ohmyzsh   = nvim ~/.local/share/oh-my-zsh
alias swayconfig = nvim ~/.config/sway

# Tools
alias tt      = taskwarrior-tui
alias gs      = git status
alias kc      = kubectl

# Zellij layouts
alias dev       = zellij --layout dev
alias config    = zellij --layout config
alias gogoNvim  = zellij -n gogoNvim
