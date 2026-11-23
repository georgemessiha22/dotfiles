function gh-token-refresh -d "Set HOMEBREW_GITHUB_API_TOKEN on demand"
    if command -q gh
        set -gx HOMEBREW_GITHUB_API_TOKEN (gh auth token)
    end
end
