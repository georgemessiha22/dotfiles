function brew_upgrade --description "Upgrade Brew packages using private fh token"
    HOMEBREW_GITHUB_API_TOKEN=$(gh auth token) brew upgrade

end
