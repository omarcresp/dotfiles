# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:
let
  user = "jackcres";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-${user}"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Bogota";

  # Select internationalisation properties.
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

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl1", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/devices/pci0000:00/0000:00:08.1/0000:04:00.0/drm/card1/card1-eDP-1/amdgpu_bl1/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl1", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/devices/pci0000:00/0000:00:08.1/0000:04:00.0/drm/card1/card1-eDP-1/amdgpu_bl1/brightness"
  '';

  # Configure console keymap
  console.keyMap = "la-latin1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable kanata
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

  # Enable upower
  services.upower.enable = true;

  # Enable unclutter
  # services.unclutter = {
  #   enable = true;
  #   timeout = 2;
  #   extraOptions = ["ignore-scrolling"];
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${user} = {
    isNormalUser = true;
    description = "Omar Crespo";
    extraGroups = [ "networkmanager" "wheel" "uinput" "input" "video" "docker" ];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ user ];
  };

  programs.wshowkeys.enable = true;

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        .zen-wrapped
      '';
      mode = "0755";
    };
  };

  # Enable automatic login for the user.
  # services.displayManager.autoLogin.enable = true;
  services.getty.autologinUser = user;
  environment.loginShellInit = ''
    if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec Hyprland
    fi
  '';

  # Install firefox.
  # programs.firefox = {
  #   enable = true;
  #   package = pkgs.firefox;
  #   nativeMessagingHosts.packages = [ pkgs.firefoxpwa ];
  # };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    gcc
    zip
    unzip
    kanata
    stable.citrix_workspace
    docker-compose
    vesktop

    # Wayland
    libsForQt5.qt5.qtwayland
    # libsForQt6.qt6.qtwayland
    libnotify
    swww
  ];

  # TODO: Research about desktop portals and alternativies
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Enables support for Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  environment.variables = {
    EDITOR = "vim";
    # LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}";
    NNN_FIFO = "/tmp/nnn.fifo";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.05"; # Did you read the comment?
}
