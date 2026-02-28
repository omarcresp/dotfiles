{ pkgs, sysRebuildCmd, ... }:
{
  home.packages = with pkgs; [
    zsh
    wget
    btop
    fastfetch
    dust
    nerd-fonts.jetbrains-mono
    zip
    unzip
    dbmate
    sqlc
  ];

  home.file = {
    ".config/tmux/tmux-killer.sh".source = ../legacy/tmux-killer.sh;
    ".config/ghostty/config".source = ../legacy/ghostty.config;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      fish_vi_key_bindings
    '';
    shellInit = ''
      fish_add_path $HOME/.local/bin
    '';
    shellAliases = {
      jn-system-switch = "sudo ${sysRebuildCmd} switch --flake $JN_DOTFILES";
      jn-update = "nix flake update --flake $JN_DOTFILES";
      jn-clean = "sudo nix-collect-garbage -d";

      chrome = "google-chrome-stable";

      # AI coding assistants
      cc = "nix run github:sadjow/claude-code-nix";
      co = "nix run github:sadjow/codex-nix";
      oc = "npx opencode-ai";
    };
  };

  programs.starship = {
    enable = true;
    enableTransience = true;
    enableBashIntegration = false;
  };

  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ];

    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    tmux.enableShellIntegration = true;
  };

  programs.sesh = {
    enable = true;
    tmuxKey = "p";
    settings = {
      window = [
        { name = "nvim"; startup_command = "nvim"; }
        { name = "claude"; startup_command = "nix run github:sadjow/claude-code-nix"; }
        { name = "lazygit"; startup_command = "lazygit"; }
        { name = "terminal"; }
      ];
      wildcard = [
        { pattern = "~/Programming/*"; windows = [ "nvim" "claude" "lazygit" "terminal" ]; }
        { pattern = "~/Programming/*/*"; windows = [ "nvim" "claude" "lazygit" "terminal" ]; }
      ];
      session = [
        {
          name = "dotfiles";
          path = "~/.config/dotfiles";
          startup_command = "nvim";
        }
      ];
    };
  };

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.tmux-fzf
      tmuxPlugins.vim-tmux-navigator
      {
        plugin = tmuxPlugins.tokyo-night-tmux;
        extraConfig = ''
          set -g @tokyo-night-tmux_theme storm

          set -g @tokyo-night-tmux_show_datetime 1
          set -g @tokyo-night-tmux_show_git 0
          set -g @tokyo-night-tmux_show_battery_widget 0
          set -g @tokyo-night-tmux_show_path 1

          set -g @tokyo-night-tmux_window_id_style none
          set -g @tokyo-night-tmux_window_id_style none
        '';
      }
    ];
    extraConfig = ''
       # Truecolor support
       set -as terminal-overrides ",*:RGB"

       set -s escape-time 0
       set -g mouse on
       set-option -g default-shell $SHELL
       set-option -g default-command $SHELL

       unbind C-b
       set -g prefix C-x

       set -g base-index 1
       set -wg pane-base-index 1

       set -wg mode-keys vi
       unbind H
       bind H resize-pane -L 5
       unbind J
       bind J resize-pane -D 5
       unbind K
       bind K resize-pane -U 5
       unbind L
       bind L resize-pane -R 5

       # Set status bar to top
       set -g status-position top

       # Reload tmux config
       unbind b
       bind b source-file $HOME/.config/tmux/tmux.conf \; display-message "Config reloaded"

      # xterm keys compatibility
       set-option -g xterm-keys on

       # Go back to main
       unbind m
       bind-key -r m run-shell 'sesh connect main'

       # Lazygit quick access
       unbind g
       bind-key -r g run-shell 'tmux neww lazygit'

       # Kill session with D
       unbind D
       bind D run-shell '$HOME/.config/tmux/tmux-killer.sh session'

       # Close window with X
       unbind X
       bind X run-shell '$HOME/.config/tmux/tmux-killer.sh window'

       # Close with x not ask for confirmation
       unbind x
       bind x run-shell '$HOME/.config/tmux/tmux-killer.sh pane'

       set -g detach-on-destroy off
    '';
  };
}
