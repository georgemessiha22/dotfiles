# env.nu — loaded before config.nu
# Ported from fish: ~/.config/fish/conf.d/000-config.fish + rustup.fish

# ─────────────────────────────────────────────────────────────────────────────
# Helper: path-add — prepend a dir to PATH if it exists and isn't already there
# ─────────────────────────────────────────────────────────────────────────────
def --env path-add [p: string] {
    let expanded = ($p | path expand)
    if ($expanded | path exists) and (not ($env.PATH | any {|x| $x == $expanded })) {
        $env.PATH = ($env.PATH | prepend $expanded)
    }
}

# Ensure PATH is a list (it normally is, but be defensive)
$env.PATH = ($env.PATH | split row (char esep) | uniq)

# ─────────────────────────────────────────────────────────────────────────────
# Homebrew shellenv (hardcoded for /opt/homebrew on Apple Silicon)
# ─────────────────────────────────────────────────────────────────────────────
$env.HOMEBREW_PREFIX = "/opt/homebrew"
$env.HOMEBREW_CELLAR = "/opt/homebrew/Cellar"
$env.HOMEBREW_REPOSITORY = "/opt/homebrew"
$env.MANPATH = ("/opt/homebrew/share/man" + (char esep) + ($env.MANPATH? | default ""))
$env.INFOPATH = ("/opt/homebrew/share/info" + (char esep) + ($env.INFOPATH? | default ""))
path-add "/opt/homebrew/bin"
path-add "/opt/homebrew/sbin"

# ─────────────────────────────────────────────────────────────────────────────
# Core env vars
# ─────────────────────────────────────────────────────────────────────────────
$env.EDITOR = "nvim"
$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"
$env.VIRTUAL_ENV_DISABLE_PROMPT = "1"
$env.XDG_CONFIG_HOME = $"($env.HOME)/.config"

# GPG / SSH
$env.GPG_TTY = (^tty | str trim)
if ($env.XDG_RUNTIME_DIR? | is-not-empty) {
    $env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/gcr/ssh"
}

# ─────────────────────────────────────────────────────────────────────────────
# Language / tool roots
# ─────────────────────────────────────────────────────────────────────────────
$env.BUN_INSTALL    = $"($env.HOME)/.local/bun"
$env.ZIG_PATH       = $"($env.HOME)/.local/zig"
$env.PROTO_HOME     = $"($env.HOME)/.proto"
$env.CARGO_HOME     = $"($env.HOME)/.local/cargo"
$env.RUSTUP_HOME    = $"($env.HOME)/.local/rustup"
$env.KREW_ROOT      = ($env.KREW_ROOT? | default $"($env.HOME)/.krew")

# ─────────────────────────────────────────────────────────────────────────────
# PATH — port of fish_add_path calls (order: most-recently-added wins on top)
# ─────────────────────────────────────────────────────────────────────────────
path-add $"($env.HOME)/.local/bin"
path-add $"($env.HOME)/.local/share/nvim/mason/bin"
path-add $"($env.HOME)/Applications/depot_tools"
path-add $"($env.HOME)/.local/go/bin"
path-add $"($env.HOME)/.local/gopkgs/bin"
path-add $"($env.BUN_INSTALL)/bin"
path-add $env.ZIG_PATH
path-add $"($env.HOME)/google-cloud-sdk/bin"
path-add $"($env.PROTO_HOME)/shims"
path-add $"($env.PROTO_HOME)/bin"
path-add $"($env.HOME)/.local/flutter/bin"
path-add $"($env.HOME)/.local/neovim/bin"
path-add $"($env.KREW_ROOT)/bin"
path-add $"($env.HOME)/go/bin"
path-add $"($env.HOME)/Library/Python/3.12/bin"
path-add "/Library/Frameworks/Python.framework/Versions/Current/bin"
path-add $"($env.HOME)/.rbenv/shims"
path-add $"($env.HOME)/Developer/flutter/bin"
path-add $"($env.HOME)/.antigravity/antigravity/bin"
path-add $"($env.CARGO_HOME)/bin"

# llvm@15 conditional flags
if ("/opt/homebrew/opt/llvm@15" | path exists) {
    $env.LDFLAGS  = "-L/opt/homebrew/opt/llvm@15/lib/c++ -Wl,-rpath,/opt/homebrew/opt/llvm@15/lib/c++"
    $env.CPPFLAGS = "-I/opt/homebrew/opt/llvm@15/include"
    path-add "/opt/homebrew/opt/llvm@15/bin"
}

# Android Studio JBR (JAVA_HOME)
if ("/Applications/Android Studio.app/Contents/jbr/Contents/Home" | path exists) {
    $env.JAVA_HOME = "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
}

# ─────────────────────────────────────────────────────────────────────────────
# nu shell paths (where generated init files live)
# ─────────────────────────────────────────────────────────────────────────────
$env.NU_CACHE = $"($env.XDG_CONFIG_HOME)/nushell/cache"
