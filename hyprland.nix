{ ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    settings = {
      monitor = [
        "eDP-1, 1366x768@60, 0x0, 1"
        "HDMI-A-1, 1920x1080@74.97, auto-left, 1"
      ];
      "exec-once" = [
        "waybar"
      ];
      "$mainMod" = "SUPER";
      bind = [
        "$mainMod, mouse:272, movewindow"

        "$mainMod, q, exec, zen"
        "$mainMod, w, exec, kitty"
        "$mainMod, e, exec, kitty nnn"

        "$mainMod, a, exec, swaync-client -t"

        "$mainMod, M, exit"

        "$mainMod, Tab, focusmonitor, +1"
      ] ++ (
        # workspaces
        # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
        builtins.concatLists (builtins.genList (i:
            let ws = i + 1;
            in [
              "$mainMod, code:1${toString i}, workspace, ${toString ws}"
              "$mainMod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
            ]
          )
          5
        )
      );
      # https://wiki.hyprland.org/Configuring/Variables/#general
      general = {
        gaps_in = 5;
        gaps_out = 8;

        border_size = 2;

        # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
        "col.active_border" = "rgba(191970ee) rgba(4b0082ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        resize_on_border = true;

        # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        allow_tearing = false;

        layout = "dwindle";
      };
    };
    extraConfig = builtins.readFile ./legacy/hyprland.conf;
  };

  services.swaync = {
    enable = true;
  };


  programs.nnn = {
    enable = true;
  };
}
