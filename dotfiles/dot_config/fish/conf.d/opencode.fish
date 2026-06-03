#!/usr/bin/env fish

function opencode_close -d "Closing and killing all opencode sessions"
    opencode session --format=json list | jq -r '"opencode session delete \(.[].id)" ' | xargs -L1 command
end
