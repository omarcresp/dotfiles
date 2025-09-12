{ pkgs, user, ... }:
{
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nix.settings.experimental-features = "nix-command flakes";

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  system.defaults = {
    dock.autohide = true;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    NSGlobalDomain.AppleShowAllExtensions = true;
    finder.ShowPathbar = true;
  };

  environment.systemPackages = with pkgs; [ vim ];

  # NOTE: Kanata - Karabiner integration not working yet
  # services.karabiner-elements.enable = true;
  # services.karabiner-elements.package = pkgs.karabiner-elements.overrideAttrs (old: {
  #   version = "14.13.0";
  #   src = pkgs.fetchurl {
  #     url = old.src.url;
  #     hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
  #   };
  #   dontFixup = true;
  # });

  nix-homebrew = {
    enable = true;
    inherit user;
  };

  homebrew = {
    enable = true;

    casks = [
      "docker"
      "zen"
      "ghostty"
      "lm-studio"
      "anydesk"
      "cursor"
      "discord"
    ];

    masApps = {
      "Ghostery" = 6504861501;
      "1PasswordSafari" = 1569813296;
    };
  };

  imports = [
    ../../modules/application.nix
    # ../../custom/kanata-darwin.nix
  ];
}
