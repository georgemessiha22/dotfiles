# enable vi mode
fish_vi_key_bindings insert
## Set values

# Hide welcome message
set fish_greeting
set VIRTUAL_ENV_DISABLE_PROMPT 1
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

## Export variable need for qt-theme
if type qtile >>/dev/null 2>&1
    set -x QT_QPA_PLATFORMTHEME qt5ct
end

# Set settings for https://github.com/franciscolourenco/done
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low


## Environment setup

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        fish_add_path -a ~/.local/bin
    end
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        fish_add_path -a ~/Applications/depot_tools
    end
end

## Add golang from .local
if test -d ~/.local/go/bin
    if not contains -- ~/.local/go/bin $PATH
        fish_add_path -a ~/.local/go/bin
    end
end

if test -d "$HOME/.local/gopkgs/"
    fish_add_path -a "$HOME/.local/gopkgs/bin"
end

## Add bun
set --export BUN_INSTALL "$HOME/.local/bun"
if test -d $BUN_INSTALL/bin
    fish_add_path -a $BUN_INSTALL/bin
end

## Add Zig
set --export ZIG_PATH "$HOME/.local/zig"
if test -d $ZIG_PATH
    fish_add_path -a $ZIG_PATH
end

# Add gcloud auth
if test -d $HOME/google-cloud-sdk/bin
    fish_add_path -a "$HOME/google-cloud-sdk/bin"
end

# proto
if test -d "$HOME/.proto"
    set -gx PROTO_HOME "$HOME/.proto"
    set -gx __ORIG_PATH $PATH

    fish_add_path -a "$PROTO_HOME/shims"
    fish_add_path -a "$PROTO_HOME/bin"
    function __proto_hook --on-variable PWD
        proto activate fish --export | source
    end
end

# flutter
if test -d "$HOME/.local/flutter/"
    fish_add_path -a "$HOME/.local/flutter/bin"
end

# if using custom build of neovim
if test -d $HOME/.local/neovim
    fish_add_path -a $HOME/.local/neovim/bin
end


# kubectl krew
set KREW_PATH "$KREW_ROOT"
test -z "$KREW_PATH"; and set KREW_PATH "$HOME/.krew"
if test -d "$KREW_PATH"
    fish_add_path -a "$KREW_PATH/bin"
end

## Functions
# Functions needed for !! and !$ https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
    switch (commandline -t)
        case "!"
            commandline -t $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ]
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end

# Fish command history
function history
    builtin history --show-time='%F %T '
end

function backup --argument filename
    cp $filename $filename.bak
end

## Aliases

# ip table coloured
alias ip='ip -color'

# Common use
alias grubup="sudo update-grub"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -xvf '
alias wget='wget -c '
alias rmpkg="sudo pacman -Rdd"
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias upd='/usr/bin/garuda-update'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='grep -F --color=auto'
alias egrep='grep -E --color=auto'
alias hw='hwinfo --short' # Hardware Info
alias big="expac -H M '%m\t%n' | sort -h | nl" # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l' # List amount of -git packages

alias cat="bat --style=grid,snip,header-filename,header-filesize"

# Cleanup orphaned packages
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'

# Get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# Recent installed packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

alias edit="nvim" # set favorite editor
alias e="nvim"

# Taskwarrior abbrv
alias tt="taskwarrior-tui"

alias zshconfig="edit ~/.zshrc"
alias ohmyzsh="edit ~/.local/share/oh-my-zsh"
alias swayconfig="edit ~/.config/sway"

## create backup
alias backitup="tar -cvzf ~/backup/backup.tar.gz --exclude .docker-cache --exclude .vs-code --exclude venv ~/Desktop ~/Documents ~/Pictures ~/.ssh ~/.gnupg"

# Kubectl abbreviation
alias kc="kubectl"

set -x SSH_AUTH_SOCK {$XDG_RUNTIME_DIR}/gcr/ssh

# Some default behaviour on mac vs linux
switch (uname)
    case Darwin
        # Add home dir XDG
        set -gx XDG_CONFIG_HOME "/Users/george/.config"

        # HOMEBREW SETUP
        eval "$(/opt/homebrew/bin/brew shellenv)"
        set --export GPG_TTY $(tty)

        # The next line updates PATH for the Google Cloud SDK.
        if test -f '$(brew --prefix)/share/google-cloud-sdk/path.fish.inc'
            source "$(brew --prefix)/share/google-cloud-sdk/path.fish.inc"
        end

        if test -d /opt/homebrew/opt/llvm@15/
            set -gx LDFLAGS -L/opt/homebrew/opt/llvm@15/lib/c++ -Wl,-rpath,/opt/homebrew/opt/llvm@15/lib/c++
            set -gx CPPFLAGS -I/opt/homebrew/opt/llvm@15/include
            fish_add_path -a /opt/homebrew/opt/llvm@15/bin
        end

        # adding go path
        if test -d $HOME/go/bin
            fish_add_path -a $HOME/go/bin/
        end

        # adding python path
        if test -d /Users/george/Library/Python/3.12/bin
            fish_add_path -a /Users/george/Library/Python/3.12/bin
        end

        if test -d $HOME/.rbenv/versions/
            status --is-interactive; and rbenv init - --no-rehash fish | source
            fish_add_path -a "$HOME/.rbenv/shims"
        end

        if test -d /Library/Frameworks/Python.framework/Versions/Current/bin
            fish_add_path -a /Library/Frameworks/Python.framework/Versions/Current/bin
        end

        # Yabai logs
        alias yabaiLogs="tail -f /tmp/yabai_$USER.out.log | sed 's/^/out: /' & tail -f /tmp/yabai_$USER.err.log | sed 's/^/err: /'"

        # skhd logs
        alias skhdLogs="tail -f /tmp/skhd_$USER.out.log | sed 's/^/out: /' & tail -f /tmp/skhd_$USER.err.log | sed 's/^/err: /'"

    case '*'
        alias hx="helix"

        # opam configuration oCaml
        if test "$HOME/.opam/opam-init/init.fish"
            source "$HOME/.opam/opam-init/init.fish" >/dev/null 2>/dev/null; or true
        end
end

# FZF because everyone is fuzzy about it.
# fzf_key_bindings

if status --is-interactive
    ## Direnv support
    direnv hook fish | source
    starship init fish | source
end

## Run fastfetch if session is interactive
if status --is-interactive && type -q macchina
    macchina -p -m -C -s
end
