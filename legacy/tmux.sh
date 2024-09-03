#!/bin/bash
SESSION="main"

if [ ! -z "$1" ]; then
  tmux $@
  exit
fi

if ! tmux has-session -t=$SESSION 2> /dev/null; then
    tmux new-session -d -s $SESSION -c "~"
fi

if [ -z "$TMUX" ]; then
  tmux attach -t $SESSION
else
  tmux switch-client -t $SESSION
fi

