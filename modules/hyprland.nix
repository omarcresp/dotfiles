{ pkgs, ... }:
let
  accent = "rgba(5d74b3cc)";
  accent_alt = "rgba(3b4a66cc)";
  border_inactive = "rgba(262b36b3)";
  shadow = "rgba(0f1115cc)";
  workspace_binds = builtins.concatLists (
    builtins.genList (
      i:
      let
        ws = i + 1;
      in
      [
        "$mainMod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
      ]
    ) 9
  );
  main_binds = [
    "$mainMod, q, killactive"
    "$mainMod, w, exec, zen-beta"
    "$mainMod, e, exec, ghostty"
    "$mainMod, r, exec, nautilus"
    "$mainMod, b, exec, swaync-client -t"
    "$mainMod, Tab, focusmonitor, +1"
    "$mainMod, X, movecurrentworkspacetomonitor, +1"
    "$mainMod, Space, exec, ulauncher-toggle"
    "$mainMod, o, exec, hyprctl dispatch pin active"
    "$mainMod, V, togglefloating"
    "$mainMod, P, pseudo"
    "$mainMod, left, movefocus, l"
    "$mainMod, right, movefocus, r"
    "$mainMod, up, movefocus, u"
    "$mainMod, down, movefocus, d"
    "$mainMod, a, workspace, 1"
    "$mainMod, s, workspace, 2"
    "$mainMod, d, workspace, 3"
    "$mainMod, f, workspace, 4"
    "$mainMod, g, workspace, 5"
    "$mainMod, h, workspace, 6"
    "$mainMod, j, workspace, 7"
    "$mainMod, k, workspace, 8"
    "$mainMod, l, workspace, 9"
    "SHIFT, Print, exec, wayshot --file ~/Pictures/shots/shot_$(date +%Y-%m-%d_%H-%M-%S).png"
    ", Print, exec, wayshot --stdout | wl-copy"
  ];
in
{
  home.packages = with pkgs; [
    wayshot
    rofi
    bluez
    rofi-bluetooth
    pavucontrol
    pulseaudioFull
    light
    wl-clipboard-rs
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    settings = {
      "$mainMod" = "SUPER";
      monitor = [
        "eDP-1, 1366x768@60, 0x0, 1"
        "HDMI-A-1, 1920x1080@60, auto-left, 1"
      ];
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
      ];
      cursor = {
        inactive_timeout = 3;
      };
      exec-once = [
        "swww-daemon"
        "waybar"
        "1password"
      ];
      input = {
        kb_layout = "latam";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
        };
      };
      gestures = {
        gesture = [
          "3, horizontal, workspace"
        ];
      };
      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        "col.active_border" = "${accent} ${accent_alt} 45deg";
        "col.inactive_border" = border_inactive;
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };
      decoration = {
        rounding = 10;
        active_opacity = 0.98;
        inactive_opacity = 0.93;
        shadow = {
          enabled = true;
          range = 16;
          render_power = 3;
          color = shadow;
        };
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          vibrancy = 0.18;
        };
      };
      animations = {
        enabled = true;
        bezier = [
          "easeOut, 0.22, 1, 0.36, 1"
          "easeIn, 0.12, 0, 0.39, 0"
          "easeInOut, 0.65, 0, 0.35, 1"
        ];
        animation = [
          "windows, 1, 7, easeOut"
          "windowsOut, 1, 6, easeIn, popin 85%"
          "border, 1, 9, easeInOut"
          "borderangle, 1, 8, easeInOut"
          "fade, 1, 6, default"
          "workspaces, 1, 6, easeOut, slide"
        ];
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      master = {
        new_status = "master";
      };
      misc = {
        force_default_wallpaper = -1;
        disable_hyprland_logo = true;
      };
      bindm = [
        "$mainMod, mouse:272, movewindow"
      ];
      bind = main_binds ++ workspace_binds;
    };
  };

  services.swaync.enable = true;
  programs.nnn = {
    enable = true;
    package = pkgs.nnn.override ({ withNerdIcons = true; });
    plugins = {
      src = "${pkgs.nnn}/share/plugins";
      mappings = {
        p = "preview-tui";
        f = "finder";
        # o = "fzopen";
        # v = "imgview";
      };
    };
    extraPackages = with pkgs; [
      ffmpegthumbnailer # for video previews
    ];
  };

  programs.waybar = {
    enable = true;
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
        # output = [
        #   "HDMI-A-1"
        # ];

        # TODO: wifi bluetooth tray
        modules-left = [
          "group/group-power"
          "hyprland/workspaces"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "temperature"
          "custom/sep"
          # "custom/bluetooth_devices"
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
          on-scroll-up = "light -A 5";
          on-scroll-down = "light -U 5";
        };

        clock = {
          format = "{:%d.%m.%Y | %H:%M}";
        };

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          on-scroll-up = "hyprctl dispatch workspace e-1";
          on-scroll-down = "hyprctl dispatch workspace e+1";
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
          # TODO: Mute button pending to review
          # "on-click-right" = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
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

        # modules-left = [ "group/group-power" ];
        # modules-center = [ "clock" ];
        # modules-right = [ "battery" ];

        # "hyprland/workspaces" = {
        #   disable-scroll = true;
        #   all-outputs = true;
        # };

        "group/group-power" = {
          "orientation" = "horizontal";
          "drawer" = {
            "transition-duration" = 500;
            "transition-left-to-right" = true;
          };
          "modules" = [
            "custom/power" # First element is the "group leader" and won't ever be hidden
            "custom/reboot"
            "custom/quit"
          ];
        };
        "custom/quit" = {
          "format" = " 󰗼 ";
          "tooltip" = false;
          "on-click" = "hyprctl dispatch exit";
        };
        "custom/reboot" = {
          "format" = " 󰜉";
          "tooltip" = false;
          "on-click" = "reboot";
        };
        "custom/power" = {
          "format" = " ";
          "tooltip" = false;
          "on-click" = "shutdown now";
        };
      };
    };
  };
}
