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
            # Control + Command + A → Desktop 1
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                97 # Key code for 'a'
                0 # Virtual key code for 'a'
                1310720 # Control + Command modifier
              ];
            };
          };
          "119" = {
            # Control + Command + S → Desktop 2
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                115 # Key code for 's'
                1 # Virtual key code for 's'
                1310720 # Control + Command modifier
              ];
            };
          };
          "120" = {
            # Control + Command + D → Desktop 3
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                100 # Key code for 'd'
                2 # Virtual key code for 'd'
                1310720 # Control + Command modifier
              ];
            };
          };
          "121" = {
            # Control + Command + F → Desktop 4
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                102 # Key code for 'f'
                3 # Virtual key code for 'f'
                1310720 # Control + Command modifier
              ];
            };
          };
          "122" = {
            # Control + Command + G → Desktop 5
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                103 # Key code for 'g'
                5 # Virtual key code for 'g'
                1310720 # Control + Command modifier
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
      "cursor"
      "docker"
      "zen"
      "ghostty"
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
