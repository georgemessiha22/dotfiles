# hooks.nu — PWD-based env_change hooks
# Ported from fish: __proto_hook, auto_run_platform_script

# Build the hooks record
let pwd_hooks = [
    # ── proto activate on directory change ─────────────────────────────────
    {|before, after|
        if (which proto | is-not-empty) {
            try {
                # proto activate prints shell-set commands; we capture exports
                # via --export which emits NAME=VALUE pairs.
                ^proto activate nu --export
                | lines
                | each {|line|
                    if ($line | str contains "=") {
                        let parts = ($line | split row -n 2 "=")
                        load-env { ($parts | get 0): ($parts | get 1 | str trim --char '"') }
                    }
                }
                | ignore
            }
        }
    }

    # ── HungerStation platform auto-loader (TODO) ───────────────────────────
    # Original fish hook sourced /Users/george/HungerStation/platform_virtual/platform.fish
    # when entering /Users/george/HungerStation/platform.
    # platform.fish has not been ported to nushell yet. To re-enable:
    #   1. Port platform.fish → platform.nu
    #   2. Uncomment the closure below.
    #
    # {|before, after|
    #     if $after == "/Users/george/HungerStation/platform" {
    #         print "Entering platform... Loading scripts!"
    #         source "/Users/george/HungerStation/platform_virtual/platform.nu"
    #     }
    # }
]

$env.config = ($env.config | upsert hooks.env_change.PWD $pwd_hooks)
