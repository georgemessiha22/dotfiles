#!/usr/bin/env fish

function zellij_kill -d "Kill and delete all Zellij sessions"
    zellij kill-all-sessions
    zellij delete-all-sessions
end
