{ pkgs, inputs, zelda64, user, ... }:
{
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "24.05";

  _module.args.inputs = inputs;

  home.sessionVariables = {
    EDITOR = "nvim";
    JN_DOTFILES = "$HOME/.config/dotfiles";

    ANTHROPIC_API_KEY =
      "";
    TAVILY_API_KEY = "";
    OPENAI_API_KEY =
      "";
    GEMINI_API_KEY = "";
    KLUSTER_API_KEY = "";
    GROQ_API_KEY = "";
    PERPLEXITY_API_KEY = "";
  };

  programs.git.signing.signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  home.file = {
    ".ssh/config".source = ../../legacy/ssh-config-nixos;
  };

  home.packages = with pkgs; [
    openssl
    ffmpeg

    delve
    exercism

    # godot_4
    # insomnia
    wayshot
    # gifski
    # ffmpeg

    rofi
    bluez
    rofi-bluetooth
    pavucontrol
    pulseaudioFull
    light
    wl-clipboard-rs

    zelda64
  ];

  home.pointerCursor = {
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
    size = 24;
    gtk.enable = true;
  };

  fonts.fontconfig.enable = true;

  imports = [
    ../../home/terminal.nix
    ../../home/development.nix
  ];

  programs.home-manager.enable = true;
}
