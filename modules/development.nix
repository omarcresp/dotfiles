{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  zig-master = inputs.zig.packages."${system}".master;
  jnvim = inputs.jack-nixvim.packages."${system}".default;
  claude-code = inputs.claude-code.packages."${system}".default;
  codex = inputs.codex.packages."${system}".default;
in
{
  home.packages = with pkgs; [
    gnumake
    # clang
    gcc
    cmake

    # delve
    # exercism

    insomnia
    dbeaver-bin
    jnvim
    claude-code
    codex
    opencode
    # flyctl
    # wrangler
    # redis
    postgresql

    lazydocker
    lazygit
    tokei
    jq
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
    pnpm
    openssl

    zig-master
  ];

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
    ];
  };

  # programs.awscli.enable = true;

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
