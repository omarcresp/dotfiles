{ user, inputs, ... }:
{
  # TODO: use variable to avoid duplicate username
  # passing inputs/especialArgs here dont work
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.05";

  _module.args.inputs = inputs;

  home.sessionVariables = {
    EDITOR = "nvim";
    JN_DOTFILES = "$HOME/.config/dotfiles";
  };

  programs.git.signing.signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  home.file = {
    ".ssh/config".source = ../../legacy/ssh-config-macos;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      fish_vi_key_bindings

      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish

      fish_add_path --prepend \
        "/etc/profiles/per-user/$USER/bin" \
        "/run/current-system/sw/bin"
    '';
    shellAliases = {
      jn-system-switch = "sudo darwin-rebuild switch --flake $JN_DOTFILES#pro";
      jn-update = "nix flake update --flake $JN_DOTFILES";
      jn-clean = "sudo nix-collect-garbage -d";

      # TODO: create this as independant CLI (or replace with sesh)
      tm = "sh $HOME/.config/tmux/tmux.sh";
    };
  };

  imports = [
    ../../home/terminal.nix
    ../../home/development.nix
  ];

  programs.home-manager.enable = true;
}

