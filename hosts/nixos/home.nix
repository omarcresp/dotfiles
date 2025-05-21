{ pkgs, inputs, zelda64, user, ... }:
{
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "24.05";

  _module.args.inputs = inputs;
  _module.args.sysRebuildCmd = "nixos-rebuild";

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

  programs.git.signing.signer = pkgs.lib.getExe' pkgs._1password-gui "op-ssh-sign";

  home.file = {
    ".ssh/config".source = ../../legacy/ssh-config-nixos;
  };

  home.packages = [ zelda64 ];

  home.pointerCursor = {
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
    size = 24;
    gtk.enable = true;
  };

  fonts.fontconfig.enable = true;

  imports = [
    ../../modules/hyprland.nix
    ../../modules/terminal.nix
    ../../modules/development.nix
  ];

  programs.home-manager.enable = true;
}
