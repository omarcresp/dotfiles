{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wayshot
    grim
    slurp
    satty
    wl-clipboard-rs
    pavucontrol
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = null;
    portalPackage = null;
    # UWSM owns the session and graphical-session.target.
    systemd.enable = false;
    extraConfig = builtins.readFile ../legacy/hyprland.lua;
  };

  services.swaync.enable = true;
  services.hyprpolkitagent.enable = true;
  services.awww.enable = true;

  programs.vicinae = {
    enable = true;
    systemd.enable = true;
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ''
      * {
        border: none;
        font-family: "JetBrainsMono", "Font Awesome 6 Pro";
        font-size: 12px;
        font-weight: 600;
        background: none;
      }

      window#waybar {
        color: #a5adcb;
      }

      .modules-left,
      .modules-right {
        border-radius: 6px;
        background: #181926;
        padding: 0 8px;
      }

      #custom-sep {
        color: #494d64;
        margin: 0 4px;
      }

      #workspaces {
        border-radius: 4px;
        padding-left: 4px;
      }

      #workspaces button {
        color: #5b6078;
        background: none;
        padding: 0;
        margin-right: 8px;
      }

      #workspaces button:hover {
        color: #a6da95;
      }

      #workspaces button.active {
        color: #f5bde6;
      }

      #temperature {
        color: #eed49f;
      }

      #clock {
        font-weight: 600;
        color: #a5adcb;
      }

      #pulseaudio {
        color: #a6da95;
      }

      #pulseaudio.muted {
        color: #ed8796;
      }

      #pulseaudio #icon {
        margin-right: 4px;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 24;
        margin = "8 8 0 8";
        spacing = 2;
        modules-left = [
          "group/group-power"
          "hyprland/workspaces"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "temperature"
          "custom/sep"
          "bluetooth"
          "tray"
          "custom/sep"
          "network"
          "pulseaudio"
          "backlight"
          "battery"
        ];

        "custom/sep" = {
          format = "|";
        };

        backlight = {
          device = "amdgpu_bl1";
          format = " {icon}  {percent}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%-";
        };

        clock = {
          format = "{:%d.%m.%Y | %H:%M}";
        };

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          on-scroll-up = "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e-1\" })'";
          on-scroll-down = "hyprctl dispatch 'hl.dsp.focus({ workspace = \"e+1\" })'";
          format-icons = {
            active = "";
            urgent = "";
            default = "";
          };
        };

        tray = {
          icon-size = 18;
          show-passive-items = "true";
          spacing = 4;
        };

        pulseaudio = {
          format = " {icon}   {volume}%";
          format-bluetooth = "{icon}   {volume}%";
          format-muted = "MUTE ";
          format-icons = {
            headphones = "";
            handsfree = "󰂑";
            headset = "󰋎";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
            ];
          };
          scroll-step = 3;
          on-click = "pavucontrol";
        };
        battery = {
          states = {
            complete = 100;
            mid = 99;
            warning = 30;
            critical = 15;
          };
          interval = 10;
          format = " {icon}  {capacity}%";
          format-full = " 󰚥  {capacity}%";
          format-complete = " 󰁹  {capacity}%";
          format-charging = " {icon}󱐋  {capacity}%";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
          ];
        };

        "group/group-power" = {
          "orientation" = "horizontal";
          "drawer" = {
            "transition-duration" = 500;
            "transition-left-to-right" = true;
          };
          "modules" = [
            "custom/power"
            "custom/reboot"
            "custom/quit"
          ];
        };
        "custom/quit" = {
          "format" = " 󰗼 ";
          "tooltip" = false;
          "on-click" = "uwsm stop";
        };
        "custom/reboot" = {
          "format" = " 󰜉";
          "tooltip" = false;
          "on-click" = "systemctl reboot";
        };
        "custom/power" = {
          "format" = " ";
          "tooltip" = false;
          "on-click" = "systemctl poweroff";
        };
      };
    };
  };
}
