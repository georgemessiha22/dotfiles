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
# Apply .profile: use this to put fish compatible .profile stuff in
if test -f ~/.fish_profile
    source ~/.fish_profile
end

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        set -p PATH ~/Applications/depot_tools
    end
end

## Add golang from .local
if test -d ~/.local/go/bin
    if not contains -- ~/.local/go/bin $PATH
        set -p PATH ~/.local/go/bin
        set -p PATH ~/.local/gopkgs/bin
        set -x GOPATH ~/.local/gopkgs
    end
end

## Add rust from .local
if test -d ~/.cargo/bin
    if not contains -- ~/.cargo/bin $PATH
        set -p PATH ~/.cargo/bin
    end
end

## Add bun
set --export BUN_INSTALL "$HOME/.bun"
if test -d $BUN_INSTALL/bin 
	fish_add_path -a $BUN_INSTALL/bin
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

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

## Useful aliases
# Replace ls with exa
# alias ls='exa -agxT -L 1' # preferred listing
# alias la='exa -algxT -L 1' # all files and dirs
# alias ll='exa -lgxT -L 1' # long format
# alias lt='exa -aT -L 1' # tree listing
# alias l.='exa -ald' # show only dotfiles
# Replace ls with lsd
alias ls='lsd ' # preferred listing
alias la='lsd ' # all files and dirs
alias ll='lsd ' # long format
alias lt='lsd ' # tree listing
alias l.='lsd ' # show only dotfiles
# ip table coloured
alias ip='ip -color'

# Replace some more things with better alternatives
# alias cat='bat -p'
[ ! -x /usr/bin/yay ] && [ -x /usr/bin/paru ] && alias yay='paru'

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

# Get fastest mirrors
alias mirror="sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"

# Help people new to Arch
alias apt='man pacman'
alias apt-get='man pacman'
alias please='sudo'
alias tb='nc termbin.com 9999'

# Cleanup orphaned packages
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'

# Get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# Recent installed packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

alias edit="nvim" # set favorite editor
alias e="nvim"
alias zshconfig="edit ~/.zshrc"
alias ohmyzsh="edit ~/.local/share/oh-my-zsh"
alias swayconfig="edit ~/.config/sway"

## create backup
alias backitup="tar -cvzf ~/backup/backup.tar.gz --exclude .docker-cache --exclude .vs-code --exclude venv ~/Desktop ~/Documents ~/Pictures ~/.ssh ~/.gnupg"

# snap 
alias snapd-start="sudo systemctl start snapd snapd.socket"
alias snapd-status="sudo systemctl status snapd snapd.socket"
alias snapd-stop="sudo systemctl stop snapd snapd.socket"

# docker control
alias dockerd-start="sudo systemctl start docker"
alias dockerd-status="sudo systemctl status docker"
alias dockerd-stop="sudo systemctl stop docker && sudo systemctl status docker"

set -x SSH_AUTH_SOCK {$XDG_RUNTIME_DIR}/ssh-agent.socket

# if using custom build of neovim
if test -d $HOME/.local/neovim
    fish_add_path $HOME/.local/neovim/bin
end

# Some default behaviour on mac vs linux
switch (uname)
    case Darwin
        # HOMEBREW SETUP
        set -gx HOMEBREW_PREFIX /opt/homebrew
        set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
        set -gx HOMEBREW_REPOSITORY /opt/homebrew
        ! set -q PATH; and set PATH ''
        set -gx PATH /opt/homebrew/bin /opt/homebrew/sbin $PATH
        ! set -q MANPATH; and set MANPATH ''
        set -gx MANPATH /opt/homebrew/share/man $MANPATH
        ! set -q INFOPATH; and set INFOPATH ''
        set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
        set --export GPG_TTY $(tty)

        # The next line updates PATH for the Google Cloud SDK.
        if [ -f '/Users/george/google-cloud-sdk/path.fish.inc' ]
            . /Users/george/google-cloud-sdk/path.fish.inc
        end

        # The next line for ruby
        # set CC compiler location this causes so many troubles
        set -gx CC /usr/bin/gcc

        if test -d /opt/homebrew/opt/ruby/bin/
            fish_add_path -a /opt/homebrew/opt/ruby/bin/
            fish_add_path -a $(gem environment gemdir)"/bin"
            set -gx CPPFLAGS -I/opt/homebrew/opt/ruby/include
            set -gx LDFLAGS -L/opt/homebrew/opt/ruby/lib
        end

        # OpenSSL postinstall
        if test -d /opt/homebrew/opt/openssl@1.1/
            fish_add_path /opt/homebrew/opt/openssl@1.1/bin
            set -gx LDFLAGS "-L/opt/homebrew/opt/openssl@1.1/lib"
            set -gx CPPFLAGS "-I/opt/homebrew/opt/openssl@1.1/include"
            set -gx PKG_CONFIG_PATH "/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"
        end
        # libressl
        # fish_add_path /opt/homebrew/opt/libressl/bin
        # set -gx LDFLAGS "-L/opt/homebrew/opt/libressl/lib"
        # set -gx CPPFLAGS "-I/opt/homebrew/opt/libressl/include"
        # set -gx PKG_CONFIG_PATH "/opt/homebrew/opt/libressl/lib/pkgconfig"

        if test -d /opt/homebrew/opt/llvm/
            set -gx LDFLAGS -L/opt/homebrew/opt/llvm/lib
            set -gx CPPFLAGS -I/opt/homebrew/opt/llvm/include
            fish_add_path -a /opt/homebrew/opt/llvm/bin
        end
        if test -d /opt/homebrew/opt/readline/
            set -gx LDFLAGS -L/opt/homebrew/opt/readline/lib
            set -gx CPPFLAGS -I/opt/homebrew/opt/readline/include
            set -gx PKG_CONFIG_PATH /opt/homebrew/opt/readline/lib/pkgconfig
        end

				if test -d $HOME/.docker/cli-plugins/
					if not test -f $HOME/.docker/cli-plugins/docker-compose
						curl -SL https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-darwin-x86_64 -o $HOME/.docker/cli-plugins/docker-compose
						chmod +x $HOME/.docker/cli-plugins/docker-compose
					end
				end
        # adding go path
        fish_add_path -a /Users/george/go/bin/

        # docker add to path
        fish_add_path -a "/Users/george/.docker/bin"

        # Add home dir XDG
        set -gx XDG_CONFIG_HOME "/Users/george/.config"

        set -gx RUBY_CONFIGURE_OPTS "--with-openssl-dir=$(brew --prefix openssl@1.1)"

        status --is-interactive; and rbenv init - fish | source

        alias colima-start="colima start --cpu 6 --memory 10 --vm-type=vz --vz-rosetta --mount-type=virtiofs --kubernetes --profile k8s"
        # copy gpg
        alias gpg-pass="printf '%s' (cat ~/Documents/recovery/gpg) | pbcopy"

    case '*'
        # copy gpg
        alias gpg-pass="printf '%s' (cat ~/Documents/recovery/gpg) | wl-copy"
        alias hx="helix"

				# opam configuration
				source /home/gmessiha/.opam/opam-init/init.fish > /dev/null 2> /dev/null; or true
end

# FZF because everyone is fuzzy about it.
# fzf_key_bindings

## Direnv support
direnv hook fish | source

starship init fish | source

## Run fastfetch if session is interactive
if status --is-interactive && type -q fastfetch
    fastfetch
end

