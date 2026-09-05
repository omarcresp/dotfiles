{ pkgs, ... }:
let
  cosmicAcPowerIdleInhibitor = pkgs.writeShellApplication {
    name = "cosmic-ac-power-idle-inhibitor";
    runtimeInputs = with pkgs; [
      coreutils
      systemd
    ];
    text = ''
      set -euo pipefail

      config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/cosmic/com.system76.CosmicIdle/v1"
      screen_off_file="$config_dir/screen_off_time"
      suspend_on_ac_file="$config_dir/suspend_on_ac_time"
      suspend_on_battery_file="$config_dir/suspend_on_battery_time"
      ac_screen_off="Some(120000)"

      mkdir -p "$config_dir"

      is_on_ac() {
        [ "$(${pkgs.systemd}/bin/busctl --system get-property org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower OnBattery 2>/dev/null || true)" = "b false" ]
      }

      write_value() {
        local file="$1"
        local value="$2"
        local current=""

        if [ -f "$file" ]; then
          current="$(tr -d '\n' < "$file")"
        fi

        if [ "$current" = "$value" ]; then
          return
        fi

        printf '%s\n' "$value" > "$file"
      }

      apply_ac_mode() {
        write_value "$screen_off_file" "$ac_screen_off"
      }

      apply_battery_mode() {
        write_value "$screen_off_file" "None"
      }

      while true; do
        write_value "$suspend_on_ac_file" "None"
        write_value "$suspend_on_battery_file" "None"

        if is_on_ac; then
          apply_ac_mode
        else
          apply_battery_mode
        fi

        sleep 15
      done
    '';
  };
in
{
  xdg.configFile."cosmic/com.system76.CosmicAppList/v1/favorites".text = ''
    [
      "zen-beta",
      "com.mitchellh.ghostty",
      "cursor",
      "com.system76.CosmicFiles",
    ]
  '';

  xdg.configFile."cosmic/com.system76.CosmicComp/v1/autotile".text = "true";
  xdg.configFile."cosmic/com.system76.CosmicComp/v1/autotile_behavior".text = "Global";
  xdg.configFile."cosmic/com.system76.CosmicComp/v1/input_touchpad".text = ''
    (state:Enabled,click_method:Some(Clickfinger),scroll_config:Some((method:Some(TwoFinger),natural_scroll:Some(true),scroll_button:None,scroll_factor:None)),tap_config:Some((enabled:true,button_map:Some(LeftRightMiddle),drag:true,drag_lock:false)))
  '';
  xdg.configFile."cosmic/com.system76.CosmicComp/v1/workspaces".text = ''
    (
      workspace_mode: OutputBound,
      workspace_layout: Horizontal,
      action_on_typing: None,
    )
  '';

  xdg.configFile."cosmic/com.system76.CosmicPanel.Dock/v1/plugins_center".text = ''
    Some([
      "com.system76.CosmicAppList",
    ])
  '';
  xdg.configFile."cosmic/com.system76.CosmicPanel.Dock/v1/plugins_wings".text = "None";

  xdg.configFile."cosmic/com.system76.CosmicPanel.Panel/v1/plugins_wings".text = ''
    Some((
      [
        "com.system76.CosmicPanelWorkspacesButton",
      ],
      [
        "com.system76.CosmicAppletStatusArea",
        "com.system76.CosmicAppletAudio",
        "com.system76.CosmicAppletBluetooth",
        "com.system76.CosmicAppletNetwork",
        "com.system76.CosmicAppletBattery",
        "com.system76.CosmicAppletNotifications",
        "com.system76.CosmicAppletPower",
      ]
    ))
  '';

  xdg.configFile."cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom".text = ''
    {
      (modifiers: [Super], key: "q"): Close,
      (modifiers: [Super], key: "w"): Spawn("zen-beta"),
      (modifiers: [Super], key: "e"): Spawn("ghostty"),
      (modifiers: [Super], key: "r"): Spawn("cosmic-files"),
      (modifiers: [Super], key: "p"): ToggleSticky,
      (modifiers: [Super], key: "v"): ToggleWindowFloating,

      (modifiers: [Super], key: "a"): Workspace(1),
      (modifiers: [Super], key: "s"): Workspace(2),
      (modifiers: [Super], key: "d"): Workspace(3),
      (modifiers: [Super], key: "f"): Workspace(4),
      (modifiers: [Super], key: "g"): Workspace(5),
      (modifiers: [Super], key: "h"): Workspace(6),
      (modifiers: [Super], key: "j"): Workspace(7),
      (modifiers: [Super], key: "k"): Workspace(8),
      (modifiers: [Super], key: "l"): Workspace(9),

      (modifiers: [Super, Shift], key: "a"): MoveToWorkspace(1),
      (modifiers: [Super, Shift], key: "s"): MoveToWorkspace(2),
      (modifiers: [Super, Shift], key: "d"): MoveToWorkspace(3),
      (modifiers: [Super, Shift], key: "f"): MoveToWorkspace(4),
      (modifiers: [Super, Shift], key: "g"): MoveToWorkspace(5),
      (modifiers: [Super, Shift], key: "h"): MoveToWorkspace(6),
      (modifiers: [Super, Shift], key: "j"): MoveToWorkspace(7),
      (modifiers: [Super, Shift], key: "k"): MoveToWorkspace(8),
      (modifiers: [Super, Shift], key: "l"): MoveToWorkspace(9),
    }
  '';

  systemd.user.services.cosmic-ac-power-idle-inhibitor = {
    Unit = {
      Description = "Manage COSMIC idle actions based on power source";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${cosmicAcPowerIdleInhibitor}/bin/cosmic-ac-power-idle-inhibitor";
      Restart = "always";
      RestartSec = 5;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
