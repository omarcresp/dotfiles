{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      fish_vi_key_bindings
    '';
    shellAliases = {
      jn-home-switch = "home-manager switch --flake $JN_DOTFILES";
      jn-system-switch = "sudo nixos-rebuild switch --flake $JN_DOTFILES";
      jn-update = "nix flake update --flake $JN_DOTFILES";

      # TODO: create this as independant CLI (or replace with sesh)
      tm = "sh $HOME/.config/tmux/tmux.sh";

      # NOTE: Development purposes
      nixvim = "nix run /home/jackcres/Programming/coding-adventure/oss/jack-nixvim/";

      svultra = "SMAPI_MODS_PATH=~/Downloads/ModsUltra steam-run $HOME/.local/share/Steam/steamapps/common/Stardew\\ Valley/StardewModdingAPI";
      svnia = "SMAPI_MODS_PATH=Mods2 steam-run $HOME/.local/share/Steam/steamapps/common/Stardew\\ Valley/StardewModdingAPI";
    };
  };

  # programs.ghostty = {
  #   enable = true;
  #   settings = {
  #     theme = "tokyonight";
  #     font-size = 10;
  #     keybind = [
  #       "ctrl+h=goto_split:left"
  #       "ctrl+l=goto_split:right"
  #     ];
  #   };
  # };

  programs.zoxide = {
    enable = true;
    enableBashIntegration= true;
    options = [ "--cmd cd" ];
  };

  # TODO: not working setting through home manager... currently set in .config files
  programs.lazygit = {
    enable = true;
    # settings = {
    #   os.openLink = "zen -P CCSolutions {{link}}";
    # };
  };
}
