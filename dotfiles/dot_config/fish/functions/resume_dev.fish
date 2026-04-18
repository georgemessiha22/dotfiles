function resume_dev -d "Resume last opened zellij session"
    ## start Zellij
    # The following snippet is meant to be used like this in your fish config:
    #
    if status --is-interactive && type -q zellij
        if not set -q ZELLIJ
            set -l zellij_sessions (zellij ls -s | string match -v "No active zellij sessions found.")
            if test -n "$zellij_sessions"
                zellij attach $zellij_sessions[1]
            else
                zellij
            end
            # Configure auto-attach/exit to your likings (default is off).
            # zellij attach $(zellij ls -s | head -1 || echo "-c")
        end
    end
end
