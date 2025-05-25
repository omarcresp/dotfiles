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
  };

  programs.git.signing.signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  home.file = {
    ".ssh/config".source = ../../legacy/ssh-config-macos;
  };

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
