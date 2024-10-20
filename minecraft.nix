{ pkgs, ... }:
{
  home.packages = with pkgs; [
    atlauncher
    temurin-jre-bin
  ];
}
