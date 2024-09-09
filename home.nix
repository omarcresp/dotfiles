{ pkgs, zen-browser, ... }:
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jackcres";
  home.homeDirectory = "/home/jackcres";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  nixpkgs.config.allowUnfree = true;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    cargo
    rustc
    silicon

    fzf
    # xclip
    zsh
    # xdotool
    lazygit
    tokei
    ripgrep
    logiops

    nodejs_20
    bun
    yarn

    discord

    # Legacy
    # wezterm

    # Install only the JetBrainsMono nerdfont
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ] ++ [
    zen-browser.packages."${pkgs.system}".default
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

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/jackcres/etc/profile.d/hm-session-vars.sh

  home.sessionVariables = {
    EDITOR = "nvim";
    JN_DOTFILES = "$HOME/.config/dotfiles/";
  };

  # Bash config
  programs.bash.enable = true;
  programs.bash.shellAliases = {
    jn-home-switch = "home-manager switch --flake $JN_DOTFILES";
    jn-system-switch = "sudo nixos-rebuild switch --flake $JN_DOTFILES";
    jn-update = "nix flake update $JN_DOTFILES";
    vi-dot = "cd $JN_DOTFILES;nvim";

    tm = "sh $HOME/.config/tmux/tmux.sh";

    # ssh management
    s-work = "rm -rf ~/.ssh && ln -s ~/.ssh-vammo ~/.ssh";
    s-home = "rm -rf ~/.ssh && ln -s ~/.ssh-omar ~/.ssh";
    s-fer = "rm -rf ~/.ssh && ln -s ~/.ssh-fer ~/.ssh";
  };

  programs.kitty = {
    enable = true;
  };

  # Enable fontconfig
  fonts.fontconfig.enable = true;

  # Enable programs
  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.zoxide = {
    enable = true;
    enableBashIntegration= true;
    options = [ "--cmd cd" ];
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
            set -g @tokyo-night-tmux_show_git 0
            set -g @tokyo-night-tmux_window_id_style none
          '';
        }
      ];
    extraConfig = ''
      set -g terminal-overrides "xterm-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

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
      bind p display-popup -w 80% -h 40% -E '$HOME/.config/tmux/z_registry.sh && SESSION_WIZARD_CMD="nvim" $HOME/.config/tmux/session-wizard.sh'
      set -g @session-wizard 'P'

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
    '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
