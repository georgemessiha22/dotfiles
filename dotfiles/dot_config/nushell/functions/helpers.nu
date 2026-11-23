# helpers.nu — pipeline-y aliases reborn as functions
# Ported from fish: psmem, psmem10, yabaiLogs, skhdLogs, backitup, backup

# Top memory consumers
export def psmem [] {
    ^ps auxf | from ssv -m 1 | sort-by --reverse "%MEM"
}

export def psmem10 [] {
    psmem | first 10
}

# Tail yabai logs (out + err, prefixed)
export def yabaiLogs [] {
    let user = $env.USER
    bash -c $"tail -f /tmp/yabai_($user).out.log | sed 's/^/out: /' & tail -f /tmp/yabai_($user).err.log | sed 's/^/err: /'"
}

# Tail skhd logs (out + err, prefixed)
export def skhdLogs [] {
    let user = $env.USER
    bash -c $"tail -f /tmp/skhd_($user).out.log | sed 's/^/out: /' & tail -f /tmp/skhd_($user).err.log | sed 's/^/err: /'"
}

# Backup important user dirs to ~/backup/backup.tar.gz
export def backitup [] {
    ^tar -cvzf $"($env.HOME)/backup/backup.tar.gz" --exclude .docker-cache --exclude .vs-code --exclude venv $"($env.HOME)/Desktop" $"($env.HOME)/Documents" $"($env.HOME)/Pictures" $"($env.HOME)/.ssh" $"($env.HOME)/.gnupg"
}

# Make a .bak copy of a file
export def backup [filename: path] {
    cp $filename $"($filename).bak"
}

# Show shell command history with timestamps (nu has built-in history)
export def hist [] {
    history | select start_timestamp command exit_status
}
