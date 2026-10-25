{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    hyprquickframe
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

  gtk = {
    enable = true;
    colorScheme = "dark";
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    # libadwaita apps already follow colorScheme; forcing a GTK3 theme on them breaks styling.
    gtk4.theme = null;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adwaita-dark";
  };

  services.swaync = {
    enable = true;
    style = ''
      @import url("file://${config.services.swaync.package}/etc/xdg/swaync/style.css");

      :root {
        --cc-bg: rgb(24, 25, 38);
        --noti-border-color: #363a4f;
        --noti-bg: 24, 25, 38;
        --noti-bg-alpha: 0.96;
        --noti-bg-darker: #1e2030;
        --noti-bg-hover: #24273a;
        --noti-bg-focus: rgba(54, 58, 79, 0.6);
        --noti-close-bg: #363a4f;
        --noti-close-bg-hover: #494d64;
        --text-color: #cad3f5;
        --text-color-disabled: #6e738d;
        --bg-selected: #5d74b3;
        --border-radius: 10px;
        --font-size-body: 13px;
        --font-size-summary: 14px;
      }

      * {
        font-family: "JetBrainsMono", "Font Awesome 6 Pro";
      }

      .widget-dnd switch:checked {
        background: #5d74b3;
      }
    '';
  };
  services.blueman-applet.enable = true;
  services.network-manager-applet.enable = true;
  # Makes nm-applet run with --indicator so it lands in waybar's SNI tray.
  xsession.preferStatusNotifierItems = true;
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

      menu,
      tooltip {
        background: #181926;
        border: 1px solid #363a4f;
        border-radius: 6px;
      }

      menuitem:hover {
        background: #363a4f;
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
          format = " {icon}";
          tooltip-format = "Brightness {percent}%";
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

        network = {
          format-wifi = "{icon}  {essid}";
          format-ethernet = "󰈀";
          format-disconnected = "󰤮";
          format-icons = [
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          on-click = "nm-connection-editor";
        };

        bluetooth = {
          format = "󰂯";
          format-off = "󰂲";
          format-disabled = "󰂲";
          format-connected = "󰂱 {num_connections}";
          tooltip-format-connected = "{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
          on-click = "blueman-manager";
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
