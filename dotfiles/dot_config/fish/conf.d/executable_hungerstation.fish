alias platform_server="docker compose run --rm -it -p "6666:6666" app nvim --listen 0.0.0.0:6666 --headless"
alias platform_editor="nvim --remote-ui --server 127.0.0.1:6666"

if which ruby >/dev/null && which gem >/dev/null
    fish_add_path -a "$(ruby -r rubygems -e 'puts Gem.user_dir')/bin"
end

alias colima-start="colima start --cpu 6 --memory 10 --disk 100 --vm-type=vz --vz-rosetta --mount-type=virtiofs --profile dev"
alias colima-stop="colima stop --profile dev"

alias pod-init='podman machine init --disk-size 100 -m 8600 --rootful'
# set -g DOCKER_SOCKET /Users/george/.local/share/containers/podman/machine/podman.sock

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/george/google-cloud-sdk/path.fish.inc' ]
    . '/Users/george/google-cloud-sdk/path.fish.inc'
end

if [ -d '/Users/george/Developer/flutter/bin' ]
    fish_add_path -a '/Users/george/Developer/flutter/bin'
end

if [ -d '/Applications/Android Studio.app/Contents/jbr/Contents/Home' ]
    set -g -x JAVA_HOME  '/Applications/Android Studio.app/Contents/jbr/Contents/Home'
end

alias hs-stg="gcloud container clusters get-credentials developer-platform-hs-staging --region europe-west1 --project hungerstation-staging"
alias hs-prod="gcloud container clusters get-credentials gdp-hs-production --region europe-west1 --project hungerstation-production"


set -Ux GOOGLE_CLOUD_PROJECT "dp-gemini-code-assist-9224"

