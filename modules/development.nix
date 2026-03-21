{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  zig-master = inputs.zig.packages."${system}".master;
  jnvim = inputs.jack-nixvim.packages."${system}".default;
  claude-code = inputs.claude-code.packages."${system}".default;
  codex = inputs.codex.packages."${system}".default;
  t3code = inputs.t3code-flake.packages."${system}".t3-code;
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
    t3code
    opencode
    # flyctl
    # wrangler
    # redis
    postgresql

    lazydocker
    gh
    lazygit
    tokei
    jq
    code2prompt
    delta
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
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        side-by-side = true;
      };
      merge.conflictstyle = "zdiff3";
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
    };
  };
}
