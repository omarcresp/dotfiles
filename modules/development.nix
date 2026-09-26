{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  zig-master = inputs.zig.packages."${system}".master;
  jnvim = inputs.jack-nixvim.packages."${system}".default;
  claude-code = inputs.claude-code.packages."${system}".default;
  codex = pkgs.callPackage ../packages/codex.nix {
    codex = inputs.codex.packages."${system}".default;
  };
  t3code = inputs.t3code-flake.packages."${system}".orchestrator;
  copilot-cli = inputs.copilot-cli.packages."${system}".default;
  vite-plus = pkgs.callPackage ../packages/vite-plus.nix { };
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
    copilot-cli
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
    ffmpeg

    # Rust
    rustc
    cargo
    silicon

    # Go
    go
    air

    # Python
    uv
    python3

    # Javascript
    nodejs_24
    vite-plus
    bun
    deno
    pnpm
    openssl

    zig-master
  ]
  # Codex shells out to bwrap for sandboxing on Linux; upstream supplied it
  # through a wrapper that the repackaged entrypoint can no longer use.
  ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.bubblewrap ];

  # The repackaged entrypoint is a plain binary rather than a wrapper, so the
  # updater opt-out has to come from the environment.
  home.sessionVariables.DISABLE_AUTOUPDATER = "1";

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
