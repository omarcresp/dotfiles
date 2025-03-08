{ pkgs, ... }:
let
  user = "jackcres";
in
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-${user}"; # Define your hostname.

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

  # Configure console keymap
  console.keyMap = "la-latin1";

  # Enable CUPS to print documents.
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
  services.kanata.keyboards.latam.config = ''
    (defsrc
      [ caps esc lctl f j ; ' )

    (defalias low (layer-while-held lower))
    (defalias raise (layer-while-held higher))

    (deflayermap (base-layer)
      esc XX
      ret XX
      bspc XX

      [ bspc
      caps (tap-hold 50 120 esc lctl)
      lctl caps
      f (tap-hold 200 250 f lalt)
      j (tap-hold 200 250 j lalt)
      k (tap-hold 200 250 k k)
      ; S-Period
      ' (tap-hold 100 150 ret lctl)
      IntlBackslash lsft
      lalt @low
      ralt @raise
    )

    (deflayermap (lower)
      tab RA-}
      q S-=
      w -
      e RA-Backslash
      r [
      u RA-Minus
      i grv
      o ]
      p Backslash
      [ del

      a S-1
      s S-2
      d S-3
      f S-4
      g S-5
      h S-6
      j S-7
      k S-8
      l S-9
      ; S-0
      ' '

      lsft IntlBackslash
      IntlBackslash IntlBackslash
      v RA-'
      n S-Minus
      m Equal
      . S-]
      / S-/
    )

    (deflayermap (higher)
      a 0
      x 1
      c 2
      v 3
      s 4
      d 5
      f 6
      w 7
      e 8
      r 9
      q RA-q

      h ArrowLeft
      j ArrowDown
      k ArrowUp
      l ArrowRight

      ; S-,
      ' S-'
      p S-Backslash
      n ;

      lsft S-IntlBackslash
      IntlBackslash S-IntlBackslash
    )
  '';

  services.upower.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    description = "Omar Crespo";
    extraGroups = [ "networkmanager" "wheel" "uinput" "input" "video" "docker" "adbusers" ];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  programs.adb.enable = true;
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ user ];
  };

  programs.wshowkeys.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

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

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    nativeMessagingHosts.packages = [ pkgs.firefoxpwa ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    gcc
    zip
    unzip
    kanata
    citrix_workspace
    docker-compose
    vesktop
    firefoxpwa

    # Wayland
    libsForQt5.qt5.qtwayland
    libnotify
    swww
  ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  environment.variables = {
    EDITOR = "vim";
    NNN_FIFO = "/tmp/nnn.fifo";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.05";
}
