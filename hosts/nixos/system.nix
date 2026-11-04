{
  lib,
  pkgs,
  user,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  boot.loader.systemd-boot.configurationLimit = 5;
  system.stateVersion = "24.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = {
    "vm.max_map_count" = 262144;
    # Tuned for zram: swap idle pages into compressed RAM early, no swap readahead.
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };

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
      "gamemode"
    ];
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "65536";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "524288";
    }
  ];

  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openvpn ];
  };

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

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

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

  services.upower.enable = true;

  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    pd.enable = true;
    settings = {
      TLP_AUTO_SWITCH = 1;
      TLP_PROFILE_AC = "PRF";
      TLP_PROFILE_BAT = "SAV";

      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_SAV = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_SAV = 0;

      # Automatic GPU clocks leave the shared APU power budget available to the CPU.
      RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
      RADEON_DPM_PERF_LEVEL_ON_SAV = "low";
      AMDGPU_ABM_LEVEL_ON_AC = 0;
      AMDGPU_ABM_LEVEL_ON_SAV = 4;

      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_SAV = "powersupersave";
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      USB_AUTOSUSPEND = 1;
    };
  };

  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    package = pkgs.steam.override {
      extraLibraries =
        p:
        pkgs.lib.optionals p.stdenv.hostPlatform.is64bit [
          p.llvmPackages.libcxx
          p.llvmPackages.libunwind
        ];
    };
  };

  programs.gamemode = {
    enable = true;
    settings.general.renice = 10;
  };

  # Follow TLP's charger profile rather than choosing a mode from CPU load.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--autopower" ];
  };
  systemd.services.scx = {
    wants = [ "tlp-pd.service" ];
    after = [ "tlp-pd.service" ];
    # TLP's profile API starts after multi-user.target.
    wantedBy = lib.mkForce [ "graphical.target" ];
  };

  # Compressed RAM swap so heavy modpacks don't page out to the NVMe swap first.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  programs.nix-ld.enable = true;

  services.getty.autologinUser = user;
  # Fish runs environment.loginShellInit through fenv in a bash subprocess, so exec has to live here.
  programs.fish.loginShellInit = ''
    if test -z "$WAYLAND_DISPLAY"; and test "$(tty)" = /dev/tty1; and uwsm check may-start
      exec uwsm start hyprland.desktop
    end
  '';

  programs._1password-gui.polkitPolicyOwners = [ user ];

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        .zen-beta
        .zen
      '';
      mode = "0755";
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    nautilus
    brightnessctl
    libnotify
    ghostty
    obs-studio
    vesktop
    remmina

    kitty
    mono
    (chafa.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [ libwebp ];
    }))

    inputs.zen-browser.packages."${system}".default
    (inputs.yt-x.packages."${system}".default.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        # yt-x passes Bash syntax to fzf, which otherwise uses the login shell.
        wrapProgram "$out/bin/yt-x" --set SHELL "${pkgs.bash}/bin/bash"
      '';
    }))
    inputs.cursor.packages."${system}".default
  ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.variables = {
    EDITOR = "nvim";
    NNN_FIFO = "/tmp/nnn.fifo";
    SSH_AUTH_SOCK = "/home/${user}/.1password/agent.sock";
  };

  imports = [
    ./hardware-configuration.nix
    ../../modules/application.nix
  ];
}
