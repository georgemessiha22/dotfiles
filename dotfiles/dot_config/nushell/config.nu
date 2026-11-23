# config.nu — Main nushell configuration
# Ported from ~/.config/fish/conf.d/* and ~/.config/fish/functions/*
#
# Loading order:
#   1. env.nu              (loaded by nushell before this file)
#   2. base $env.config    (set here, MUST exist before theme/hooks)
#   3. theme               (mutates $env.config.color_config etc.)
#   4. plugins             (skim — must be `plugin use` so commands are visible)
#   5. tool init           (zoxide, atuin — sourced from cache; starship is last)
#   6. aliases / functions
#   7. hooks               (mutates $env.config.hooks)
#   8. work overrides      (hungerstation.nu)
#   9. direnv hook         (appended to PWD env_change hooks)
#  10. macchina            (interactive welcome)
#  11. starship            (LAST — owns the prompt)

# ─────────────────────────────────────────────────────────────────────────────
# 1. Base $env.config — vi mode, banner off, history, sensible defaults
# ─────────────────────────────────────────────────────────────────────────────
$env.config = {
    show_banner: false
    edit_mode: vi
    history: {
        max_size: 100000
        sync_on_enter: true
        file_format: plaintext
        isolation: false
    }
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: fuzzy
        external: {
            enable: true
            max_results: 100
        }
    }
    rm: { always_trash: false }
    use_kitty_protocol: false
    cursor_shape: {
        emacs: line
        vi_insert: line
        vi_normal: block
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. Theme (catppuccin macchiato)
# ─────────────────────────────────────────────────────────────────────────────
source ~/.config/nushell/themes/catppuccin_macchiato.nu

# ─────────────────────────────────────────────────────────────────────────────
# 3. Plugins
# ─────────────────────────────────────────────────────────────────────────────
# nu_plugin_skim provides `sk` — fzf-style fuzzy finder, native to nushell.
# Register once with: plugin add ~/.local/cargo/bin/nu_plugin_skim
plugin use skim

# ─────────────────────────────────────────────────────────────────────────────
# 4. Tool init (cached — regenerate with the snippets below)
# To refresh:
#   zoxide  init nushell | save -f ~/.config/nushell/cache/zoxide.nu
#   atuin   init nu      | save -f ~/.config/nushell/cache/atuin.nu
#   starship init nu     | save -f ~/.config/nushell/cache/starship.nu
# (starship is loaded LAST, at the bottom of this file)
# ─────────────────────────────────────────────────────────────────────────────
source ~/.config/nushell/cache/zoxide.nu
source ~/.config/nushell/cache/atuin.nu

# ─────────────────────────────────────────────────────────────────────────────
# 5. Aliases
# ─────────────────────────────────────────────────────────────────────────────
source ~/.config/nushell/aliases.nu

# ─────────────────────────────────────────────────────────────────────────────
# 6. User functions (each file `export def`s its commands)
# ─────────────────────────────────────────────────────────────────────────────
use ~/.config/nushell/functions/helpers.nu *
use ~/.config/nushell/functions/nvims.nu
use ~/.config/nushell/functions/push2stg.nu
use ~/.config/nushell/functions/resume_dev.nu
use ~/.config/nushell/functions/chezmoi_cp.nu
use ~/.config/nushell/functions/opencode_close.nu
use ~/.config/nushell/functions/zellij_kill.nu

# ─────────────────────────────────────────────────────────────────────────────
# 7. Hooks (PWD-based)
# ─────────────────────────────────────────────────────────────────────────────
source ~/.config/nushell/hooks.nu

# ─────────────────────────────────────────────────────────────────────────────
# 8. Work-specific overrides (env, PATH, aliases for HungerStation)
# ─────────────────────────────────────────────────────────────────────────────
source ~/.config/nushell/hungerstation.nu

# ─────────────────────────────────────────────────────────────────────────────
# 9. direnv hook (PWD env_change — appended)
# ─────────────────────────────────────────────────────────────────────────────
if (which direnv | is-not-empty) {
    $env.config.hooks.env_change.PWD = (
        $env.config.hooks.env_change.PWD | append {|before, after|
            try {
                ^direnv export json
                | from json
                | default {}
                | items {|k, v|
                    if $v == null {
                        hide-env -i $k
                    } else {
                        load-env { ($k): $v }
                    }
                }
                | ignore
            }
        }
    )
}

# ─────────────────────────────────────────────────────────────────────────────
# 10. Starship — MUST be the LAST thing loaded so it wins ownership of the
#     prompt (PROMPT_COMMAND, PROMPT_INDICATOR_VI_*, etc.) after any other
#     module or hook that might touch prompt env vars.
# ─────────────────────────────────────────────────────────────────────────────
source ~/.config/nushell/cache/starship.nu

# ─────────────────────────────────────────────────────────────────────────────
# 11. macchina on interactive launch (mirrors fish's status --is-interactive block)
# ─────────────────────────────────────────────────────────────────────────────
if $nu.is-interactive and (which macchina | is-not-empty) {
    ^macchina -p -m -C -s
}

