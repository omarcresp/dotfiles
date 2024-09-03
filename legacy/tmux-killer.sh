current_session=$(tmux display-message -p '#S')
current_window=$(tmux display-message -p '#I')
current_pane=$(tmux display-message -p '#P')

close_sesion() {
    if [ "$(tmux list-sessions | wc -l)" = "1" ]; then
        tmux kill-session
    fi

    main_sesion=$(tmux list-sessions | grep -v "main" | wc -l)

    if [ "$main_sesion" = "1" ] && [ $current_session != "main" ]; then
        tmux switch-client -t main
    else
        tmux switch-client -n
    fi

    tmux kill-session -t $current_session
}

close_window() {
    if [ "$(tmux list-windows | wc -l)" = "1" ]; then
        close_sesion
    else
        tmux kill-window -t $current_window
    fi
}

close_pane() {
    if [ "$(tmux list-panes | wc -l)" = "1" ]; then
        close_window
    else
        tmux kill-pane -t $current_pane
    fi
}

display_help() {
    echo "Usage: tmux-killer.sh [session|window|pane]"
}

if [ -z "$TMUX" ]; then
    echo "No tmux session found"
    exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    display_help
    exit 0
fi

if [ "$1" = "session" ]; then
    close_sesion 
elif [ "$1" = "window" ]; then
    close_window
elif [ "$1" = "pane" ]; then
    close_pane
else
    echo "Invalid argument"
    display_help
    exit 1
fi

