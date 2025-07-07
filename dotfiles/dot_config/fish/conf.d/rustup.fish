set -gx CARGO_HOME $HOME/.local/cargo
set -gx RUSTUP_HOME $HOME/.local/rustup

## Add rust from .local
if test -e $HOME/.local/cargo/env.fish
    . $HOME/.local/cargo/env.fish
end
