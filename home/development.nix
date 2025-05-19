{ pkgs, inputs, ...}: {
  home.packages = with pkgs; [
    gnumake
    clang
    cmake

    dbeaver-bin
    code-cursor

    lazydocker
    lazygit
    supabase-cli
    tokei

    rustc
    cargo

    go
    air

    nodejs
    bun
    biome
    deno

    inputs.zig.packages."${pkgs.system}".master
  ];

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
    ];
  };

  programs.git = {
    enable = true;
    userEmail = "crespomerchano@gmail.com";
    userName = "Omar Crespo";
    extraConfig = {
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
    };
  };
}
