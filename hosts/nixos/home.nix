{
  pkgs,
  inputs,
  user,
  ...
}:
{
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "24.05";
  home.enableNixpkgsReleaseCheck = false;

  _module.args.inputs = inputs;
  _module.args.sysRebuildCmd = "nixos-rebuild";

  home.sessionVariables = {
    EDITOR = "nvim";
    JN_DOTFILES = "$HOME/.config/dotfiles";
    SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";

    ANTHROPIC_API_KEY = "";
    TAVILY_API_KEY = "";
    OPENAI_API_KEY = "";
    GEMINI_API_KEY = "";
    KLUSTER_API_KEY = "";
    GROQ_API_KEY = "";
    PERPLEXITY_API_KEY = "";
  };

  programs.git.signing.signer = pkgs.lib.getExe' pkgs._1password-gui "op-ssh-sign";

  home.packages = [
    pkgs.zelda64recomp
    pkgs.prismlauncher
    pkgs.temurin-bin-25
  ];

  home.pointerCursor = {
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
    size = 24;
    gtk.enable = true;
  };

  fonts.fontconfig.enable = true;

  imports = [
    ../../modules/cosmic.nix
    ../../modules/terminal.nix
    ../../modules/development.nix
  ];

  programs.mpv = {
    enable = true;
    config = {
      # Hide UI
      osc = false;
      osd-bar = false;
      osd-level = 0;
      border = false;
      fs = true;

      hwdec = "auto-safe";
      hwdec-codecs = "h264,vc1,hevc,vp8,vp9,prores";
      vo = "gpu-next";
      msg-level = "ffmpeg=error";

      # Disable post-processing
      deband = false;
      dither-depth = "no";
      interpolation = false;

      # Fastest scalers
      scale = "bilinear";
      dscale = "bilinear";
      cscale = "bilinear";

      # Limit buffer to save RAM
      demuxer-max-bytes = "30M";
      demuxer-max-back-bytes = "12M";

      ytdl-format = "bestvideo[height<=?1440][vcodec~='^(avc|h264)']+bestaudio/bestvideo[height<=?1440]+bestaudio/best";
    };
  };

  programs.home-manager.enable = true;
}
