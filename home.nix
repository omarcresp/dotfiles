{ pkgs, inputs, zelda64, ... }:
{
  home.username = "jackcres";
  home.homeDirectory = "/home/jackcres";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    zenity
    unrar

    cargo
    rustc
    silicon
    gnumake
    openssl

    go
    air
    delve
    exercism

    clang
    cmake
    # flutter
    # ninja
    # pkg-config

    # Nia
    anydesk

    vlc
    nautilus
    libsForQt5.kdenlive

    btop
    fastfetch
    fzf
    jq
    lazydocker
    tokei
    cloc
    scc
    dust
    # logiops

    nodejs_20
    # bun
    # yarn
    # biome
    deno
    # sqlc
    # flyway

    godot_4

    # insomnia
    # code-cursor
    vesktop
    obs-studio
    wayshot
    # gifski
    ffmpeg

    rofi
    bluez
    rofi-bluetooth
    pavucontrol
    pulseaudioFull
    light
    wl-clipboard-rs

    nerd-fonts.jetbrains-mono
  ] ++ [
      inputs.zen-browser.packages."${pkgs.system}".default

      # inputs.hcp-cli.packages."${pkgs.system}".default

      inputs.ulauncher.packages."${pkgs.system}".default

      inputs.zig.packages."${pkgs.system}".master

      stable.pulumi
      stable.pulumiPackages.pulumi-language-nodejs

      zelda64

      inputs.jack-nixvim.packages.${pkgs.system}.default
    ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".wezterm.lua".source = ./legacy/wezterm.lua;
    ".config/tmux/tmux-killer.sh".source = ./legacy/tmux-killer.sh;
    ".config/tmux/session-wizard.sh".source = ./legacy/session-wizard.sh;
    ".config/tmux/tmux.sh".source = ./legacy/tmux.sh;
    ".config/tmux/z_registry.sh".source = ./legacy/z_registry.sh;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.pointerCursor = {
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
    size = 24;
    gtk.enable = true;
  };


  programs.starship = {
    enable = true;
    enableTransience = true;
    enableBashIntegration = false;
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
    ];
  };


  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono";
      size = 12;
    };
    settings = {
      allow_remote_control = "yes";
      # background_opacity = "0.9";
    };
    themeFile = "tokyo_night_night";
  };

  # Enable fontconfig
  fonts.fontconfig.enable = true;

  # Enable programs
  # programs.git.enable = true;
  programs.git = {
    enable = true;
    extraConfig = {
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
    };
  };

  # Tmux conf
  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    # historyLimit = 100000;
    plugins = with pkgs;
      [
        tmuxPlugins.sensible
        tmuxPlugins.tmux-fzf
        tmuxPlugins.vim-tmux-navigator
        {
          plugin = tmuxPlugins.tokyo-night-tmux;
          extraConfig = ''
            set -g @tokyo-night-tmux_show_datetime 0
            set -g @tokyo-night-tmux_show_git 0
            set -g @tokyo-night-tmux_show_battery_widget 0
            set -g @tokyo-night-tmux_show_path 1

            set -g @tokyo-night-tmux_window_id_style none
            set -g @tokyo-night-tmux_window_id_style none
          '';
        }
      ];
    extraConfig = ''
      set -s escape-time 0

      set -g mouse on

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

      # Fzf key bindings
      unbind p
      unbind P
      bind P display-popup -w 80% -h 40% -E '$HOME/.config/tmux/z_registry.sh && SESSION_WIZARD_CMD="nvim" $HOME/.config/tmux/session-wizard.sh'
      bind p display-popup -w 80% -h 40% -E '$HOME/.config/tmux/z_registry.sh && $HOME/.config/tmux/session-wizard.sh'

      # Set status bar to top
      set -g status-position top

      # xterm keys compatibility
      set-option -g xterm-keys on

      # Go back to main
      unbind m
      bind-key -r m run-shell '$HOME/.config/tmux/tmux.sh'

      # Lazygit quick access
      unbind g
      bind-key -r g run-shell 'tmux neww lazygit'

      # Reload tmux config
      unbind b
      bind b source-file $HOME/.config/tmux/tmux.conf \; display-message "Config reloaded"

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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  imports = [ ./hyprland.nix ./minecraft.nix ./secrets.nix ./terminal.nix ];
}
