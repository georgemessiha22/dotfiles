# resume_dev.nu — resume last zellij session
# Ported from fish: ~/.config/fish/functions/resume_dev.fish

export def --wrapped main [...args] {
    if not ($nu.is-interactive) { return }
    if (which zellij | is-empty) { return }
    if ($env.ZELLIJ? | is-not-empty) { return }

    let sessions = (
        ^zellij ls -s
        | lines
        | where {|l| $l != "No active zellij sessions found." and ($l | str trim | is-not-empty)}
    )

    if ($sessions | is-not-empty) {
        ^zellij attach ($sessions | get 0)
    } else {
        ^zellij
    }
}
