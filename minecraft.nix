{ pkgs, ... }:
{
  home.packages = with pkgs; [
    prismlauncher
    temurin-bin-21

    mgba
    # dualsensectl
  ];
}
