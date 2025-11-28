{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  zig-master = inputs.zig.packages."${system}".master;
  jnvim = inputs.jack-nixvim.packages."${system}".default;
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
    flyctl
    wrangler
    redis
    postgresql

    lazydocker
    lazygit
    tokei
    code2prompt
    docker-compose

    # Rust
    rustc
    cargo
    silicon

    # Go
    go
    air

    # Python
    uv

    # Javascript
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

  # programs.awscli.enable = true;
  programs.codex.enable = true;

  programs.git = {
    enable = true;
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFY5mL5Pt4Djk2AibDNdHLvXwXmCSiX2Qze+hbhDMP/D";
      format = "ssh";
      signByDefault = true;
    };
    settings = {
      user = {
        email = "crespomerchano@gmail.com";
        name = "Omar Crespo";
      };
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
    };
  };
}
