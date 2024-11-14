
function push2stg -d "Create Staging version branch of current branch"
    argparse h/help n/num_commits= -- $argv
    or return

    if set -ql _flag_help
        echo "
        Create a staging branch of current branch on platform
        Options:
          -n number of commits to be cherry-picked
       "
        return
    end

    if set -ql _flag_num_commits
        echo "Number of commits to cherry pick: $_flag_num_commits"
        set first_hash "$(git rev-parse HEAD~"$_flag_num_commits")"
        set last_hash "$(git rev-parse HEAD)"
        set branch_name "$(git rev-parse --abbrev-ref HEAD)"
				set repo_name "$(git config --get remote.origin.url | rev | cut -d/ -f1 | rev | cut -d. -f1)"
				set owner_name "$(git config --get remote.origin.url | rev | cut -d/ -f2 | rev | cut -d: -f2)"

        echo "
				repo owner=$owner_name
				repo Name=$repo_name
				first_hash=$first_hash
				last_hash=$last_hash
				branch_name=$branch_name
				"

        git fetch || exit 1
        git branch -D staging
        git checkout staging
        git pull --rebase origin staging
        git branch -D "$branch_name-stg" || true
        git checkout -b "$branch_name-stg"
				git cherry-pick --abort || true
        git cherry-pick "$first_hash".."$last_hash"
        git push --set-upstream origin "$branch_name-stg" -f
        open "https://github.com/$owner_name/$repo_name/compare/staging...$branch_name-stg?expand=1"
        git checkout "$branch_name"
        git branch -D "$branch_name-stg"
        git branch -D staging
    end
end
