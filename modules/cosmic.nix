{ ... }:
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
}
