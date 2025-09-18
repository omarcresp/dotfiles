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

    CustomUserPreferences = {
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          "118" = {
            # Control + A → Desktop 1
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                97 # Key code for 'a'
                0 # Virtual key code for 'a'
                262144 # Control modifier
              ];
            };
          };
          "119" = {
            # Control + S → Desktop 2
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                115 # Key code for 's'
                1 # Virtual key code for 's'
                262144 # Control modifier
              ];
            };
          };
          "120" = {
            # Control + D → Desktop 3
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                100 # Key code for 'd'
                2 # Virtual key code for 'd'
                262144 # Control modifier
              ];
            };
          };
          "121" = {
            # Control + F → Desktop 4
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                102 # Key code for 'f'
                3 # Virtual key code for 'f'
                262144 # Control modifier
              ];
            };
          };
          "122" = {
            # Control + G → Desktop 5
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                103 # Key code for 'g'
                5 # Virtual key code for 'g'
                262144 # Control modifier
              ];
            };
          };
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ vim ];

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
      "cursor"
    ];

    masApps = {
      "Ghostery" = 6504861501;
      "1PasswordSafari" = 1569813296;
      "SessionPomodoroFocusTimer" = 1521432881;
    };
  };

  imports = [
    ../../modules/application.nix
  ];
}
