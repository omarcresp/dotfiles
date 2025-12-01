{
  pkgs,
  user,
  inputs,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.stateVersion = "24.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-${user}"; # Define your hostname.
  users.users.${user} = {
    isNormalUser = true;
    description = "Omar Crespo";
    extraGroups = [
      "networkmanager"
      "wheel"
      "uinput"
      "input"
      "video"
      "docker"
      "adbusers"
      "wireshark"
    ];
  };

  networking.networkmanager.enable = true;

  time.timeZone = "America/Bogota";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_CO.UTF-8";
    LC_IDENTIFICATION = "es_CO.UTF-8";
    LC_MEASUREMENT = "es_CO.UTF-8";
    LC_MONETARY = "es_CO.UTF-8";
    LC_NAME = "es_CO.UTF-8";
    LC_NUMERIC = "es_CO.UTF-8";
    LC_PAPER = "es_CO.UTF-8";
    LC_TELEPHONE = "es_CO.UTF-8";
    LC_TIME = "es_CO.UTF-8";
  };

  programs.hyprland.enable = true;

  # Screen bright patch
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl1", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/devices/pci0000:00/0000:00:08.1/0000:04:00.0/drm/card1/card1-eDP-1/amdgpu_bl1/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl1", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/devices/pci0000:00/0000:00:08.1/0000:04:00.0/drm/card1/card1-eDP-1/amdgpu_bl1/brightness"
  '';

  console.keyMap = "la-latin1";

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.kanata.enable = true;
  services.kanata.keyboards.latam.config = builtins.readFile ../../legacy/kanata-linux.cfg;

  services.mullvad-vpn.enable = true;

  services.upower.enable = true;

  programs.wireshark = {
    enable = true;
    dumpcap.enable = true;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  programs.wshowkeys.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs._1password-gui.polkitPolicyOwners = [ user ];

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        .zen-wrapped
      '';
      mode = "0755";
    };
  };

  services.getty.autologinUser = user;
  environment.loginShellInit = ''
    if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec Hyprland
    fi
  '';

  environment.systemPackages = with pkgs; [
    vim
    # TODO: replace with flake. flake is missing darwin support
    code-cursor
    mullvad-vpn

    nautilus
    ghostty
    obs-studio
    anydesk

    # Wayland
    libsForQt5.qt5.qtwayland
    libnotify
    swww

    inputs.zen-browser.packages."${pkgs.system}".default
    google-chrome
    inputs.ulauncher.packages."${pkgs.system}".default
  ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  environment.variables = {
    EDITOR = "nvim";
    NNN_FIFO = "/tmp/nnn.fifo";
  };

  imports = [
    ./hardware-configuration.nix
    ../../modules/application.nix
  ];
}
