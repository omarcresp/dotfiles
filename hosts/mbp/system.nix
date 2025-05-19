{ pkgs, inputs, user, ... }: {
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

  environment.systemPackages = with pkgs; [ vim ] ++ [
    inputs.jack-nixvim.packages.${pkgs.system}.default
  ];

  # BUG: Karabiner Elements 14 license expired. waiting on nix-darwin support
  # https://github.com/nix-darwin/nix-darwin/issues/1041
  # services.karabiner-elements.enable = true;

  # TODO: define if 1password place its there
  programs._1password.enable = true;
  programs._1password-gui.enable = true;

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
    ];
  };

  # imports = [ ../../custom/kanata-darwin.nix ];
}
