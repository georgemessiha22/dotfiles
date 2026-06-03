# chezmoi_cp.nu — chezmoi add → amend → force-push
# Ported from fish: ~/.config/fish/functions/chezmoi-cp.fish

export def main [] {
    print $"(ansi red)Chezmoi diff(ansi reset)"
    print $"(ansi yellow)"
    ^chezmoi git status -- --no-branch -s
    print $"(ansi reset)"

    print $"(ansi red)Chezmoi committing(ansi reset)"
    print $"(ansi blue)"
    ^chezmoi git add -- .
    ^chezmoi git commit -- --amend --no-edit
    print $"(ansi reset)"

    print $"(ansi red)Chezmoi pushing(ansi reset)"
    print $"(ansi blue)"
    ^chezmoi git push -- -f
    print $"(ansi reset)"
}
