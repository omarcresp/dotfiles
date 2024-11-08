{ pkgs, ... }:
{
  home.packages = with pkgs; [
    prismlauncher
    temurin-bin-21

    unrar
    mgba
    dualsensectl
  ];
}
