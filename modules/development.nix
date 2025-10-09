{ pkgs, inputs, ... }:
let
  zig-master = inputs.zig.packages."${pkgs.system}".master;
  jnvim = inputs.jack-nixvim.packages.${pkgs.system}.default;
in
{
  home.packages = with pkgs; [
    gnumake
    clang
    cmake

    # delve
    # exercism

    insomnia
    dbeaver-bin
    jnvim
    claude-code

    lazydocker
    lazygit
    tokei
    docker-compose

    rustc
    cargo
    silicon

    go
    air

    nodejs
    bun
    deno

    zig-master
  ];

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
    ];
  };

  programs.awscli.enable = true;
  programs.codex.enable = true;

  programs.git = {
    enable = true;
    userEmail = "crespomerchano@gmail.com";
    userName = "Omar Crespo";
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFY5mL5Pt4Djk2AibDNdHLvXwXmCSiX2Qze+hbhDMP/D";
      format = "ssh";
      signByDefault = true;
    };
    extraConfig = {
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
    };
  };
}
