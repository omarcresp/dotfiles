{ config, user, inputs, ... }:
let
  androidSdk = "${config.home.homeDirectory}/Library/Android/sdk";
in
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.05";
  home.enableNixpkgsReleaseCheck = false;

  _module.args.inputs = inputs;
  _module.args.sysRebuildCmd = "darwin-rebuild";

  home.sessionVariables = {
    ANDROID_HOME = androidSdk;
    EDITOR = "nvim";
    JN_DOTFILES = "$HOME/.config/dotfiles";
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  home.sessionPath = [
    "${androidSdk}/emulator"
    "${androidSdk}/platform-tools"
  ];

  programs.git.signing.signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

  # GUI apps launched by launchd (Dock/Finder/Spotlight) inherit launchd's
  # SSH_AUTH_SOCK -- Apple's stub agent, which holds zero identities -- so the
  # sessionVariables entry above never reaches them and git push fails with
  # "Permission denied (publickey)". T3 Code makes this worse: it probes the
  # login shell for env but only adopts SSH_AUTH_SOCK when unset, so launchd's
  # broken value always wins.
  #
  # IdentityAgent pins the 1Password agent at the ssh layer, which overrides
  # SSH_AUTH_SOCK entirely and works from any launch context. Quotes are part of
  # the value: the path contains spaces and home-manager does not quote for us.
  programs.ssh = {
    enable = true;
    # Avoids the deprecation warning for the legacy default block; we had no
    # ~/.ssh/config before this, so there are no old defaults worth preserving.
    enableDefaultConfig = false;
    settings."*".IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
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
    ../../modules/cliproxyapi.nix
  ];

  programs.home-manager.enable = true;
}
