{ ... }:
{
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
