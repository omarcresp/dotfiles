{ user, inputs, ... }:
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.05";

  _module.args.inputs = inputs;
  _module.args.sysRebuildCmd = "darwin-rebuild";

  home.sessionVariables = {
    EDITOR = "nvim";
    JN_DOTFILES = "$HOME/.config/dotfiles";
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  programs.git.signing.signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

  programs.fish.shellInit = ''
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish

    fish_add_path --prepend \
      "/etc/profiles/per-user/$USER/bin" \
      "/run/current-system/sw/bin"
  '';

  imports = [
    ../../modules/terminal.nix
    ../../modules/development.nix
  ];

  programs.home-manager.enable = true;
}
