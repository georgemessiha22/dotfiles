# push2stg.nu — create a staging version of the current branch
# Ported from fish: ~/.config/fish/functions/push2stg.fish

export def main [
    --num_commits (-n): int   # number of commits to cherry-pick
    --help (-h)               # show help
] {
    if $help {
        print "Create a staging branch of current branch"
        print "Options:"
        print "  -n  number of commits to be cherry-picked"
        return
    }

    if $num_commits == null {
        print "Error: -n <num_commits> is required"
        return
    }

    print $"Number of commits to cherry pick: ($num_commits)"

    let first_hash  = (^git rev-parse $"HEAD~($num_commits)" | str trim)
    let last_hash   = (^git rev-parse HEAD | str trim)
    let branch_name = (^git rev-parse --abbrev-ref HEAD | str trim)
    let remote_url  = (^git config --get remote.origin.url | str trim)
    let repo_name   = ($remote_url | str replace --regex '\.git$' '' | path basename)
    let owner_name  = ($remote_url | str replace --regex '\.git$' '' | path dirname | path basename)

    print $"repo owner=($owner_name)"
    print $"repo name =($repo_name)"
    print $"first_hash=($first_hash)"
    print $"last_hash =($last_hash)"
    print $"branch    =($branch_name)"

    ^git fetch
    try { ^git branch -D staging }
    ^git checkout staging
    ^git pull --rebase origin staging
    try { ^git branch -D $"($branch_name)-stg" }
    ^git checkout -b $"($branch_name)-stg"
    try { ^git cherry-pick --abort }
    ^git cherry-pick $"($first_hash)..($last_hash)"
    ^git push --set-upstream origin $"($branch_name)-stg" -f
    ^open $"https://github.com/($owner_name)/($repo_name)/compare/staging...($branch_name)-stg?expand=1"
    ^git checkout $branch_name
    try { ^git branch -D $"($branch_name)-stg" }
    try { ^git branch -D staging }
}
