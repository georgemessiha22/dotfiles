function chezmoi-cp --description 'Chezmoi add-commit-push'
    set_color red
    echo "Chezmoi diff"
    set_color yellow
    command chezmoi git status -- --no-branch -s
    set_color red
    echo "Chezmoi committing"
    set_color blue
    command chezmoi git add -- .
    command chezmoi git commit -- --amend --no-edit
    set_color red
    echo "Chezmoi pushing"
    set_color blue
    command chezmoi git push -- -f
end
