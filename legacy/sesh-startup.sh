#!/usr/bin/env bash
# Auto-layout for sesh sessions under any Programming directory.
# Layout: 1=nvim  2=claude  3=lazygit  4=terminal
# Otherwise: plain terminal.

if [[ "$PWD" =~ /Programming(/|$) ]]; then
    tmux rename-window "nvim"

    tmux new-window -n "claude" -d
    tmux send-keys -t ":claude" "cc" Enter

    tmux new-window -n "lazygit" -d
    tmux send-keys -t ":lazygit" "lazygit" Enter

    tmux new-window -n "terminal" -d

    tmux select-window -t 1
    exec nvim
else
    exec "$SHELL"
fi
