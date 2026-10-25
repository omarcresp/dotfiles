local mainMod = "SUPER"

local accent = "rgba(5d74b3cc)"
local accentAlt = "rgba(3b4a66cc)"
local borderInactive = "rgba(262b36b3)"
local shadow = "rgba(0f1115cc)"

hl.monitor({ output = "eDP-1", mode = "1366x768@60", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "auto-left", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.on("hyprland.start", function()
  hl.exec_cmd("uwsm app -- 1password")
end)

hl.config({
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },

  cursor = {
    inactive_timeout = 3,
  },

  input = {
    kb_layout = "latam",
    follow_mouse = 1,
    sensitivity = 0,

    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      tap_to_click = true,
      tap_and_drag = true,
      drag_lock = false,
    },
  },

  general = {
    gaps_in = 6,
    gaps_out = 12,
    border_size = 2,

    col = {
      active_border = { colors = { accent, accentAlt }, angle = 45 },
      inactive_border = borderInactive,
    },

    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 10,
    active_opacity = 0.98,
    inactive_opacity = 0.93,

    shadow = {
      enabled = true,
      range = 16,
      render_power = 3,
      color = shadow,
    },

    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      vibrancy = 0.18,
    },
  },

  animations = {
    enabled = true,
  },

  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
  },
})

hl.curve("easeOut", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("easeIn", { type = "bezier", points = { { 0.12, 0 }, { 0.39, 0 } } })
hl.curve("easeInOut", { type = "bezier", points = { { 0.65, 0 }, { 0.35, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "easeOut" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 6, bezier = "easeIn", style = "popin 85%" })
hl.animation({ leaf = "border", enabled = true, speed = 9, bezier = "easeInOut" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "easeInOut" })
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "easeOut", style = "slide" })

for _, class in ipairs({ "blueman-manager", "nm-connection-editor", "org.pulseaudio.pavucontrol" }) do
  hl.window_rule({
    name = "float-" .. class,
    match = { class = class },
    float = true,
    size = "720 480",
    center = true,
  })
end

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

local function bindMod(keys, dispatcher, opts)
  hl.bind(mainMod .. " + " .. keys, dispatcher, opts)
end

local function app(cmd)
  return hl.dsp.exec_cmd("uwsm app -- " .. cmd)
end

bindMod("q", hl.dsp.window.close())
bindMod("w", app("zen-beta"))
bindMod("e", app("ghostty"))
bindMod("r", app("nautilus"))
bindMod("b", hl.dsp.exec_cmd("swaync-client -t"))
bindMod("Space", hl.dsp.exec_cmd("vicinae toggle"))
bindMod("c", hl.dsp.exec_cmd("vicinae deeplink vicinae://launch/clipboard/history"))
bindMod("Tab", hl.dsp.focus({ monitor = "+1" }))
bindMod("x", hl.dsp.workspace.move({ monitor = "+1" }))
bindMod("o", hl.dsp.window.pin())
bindMod("p", hl.dsp.window.pin())
bindMod("v", hl.dsp.window.float({ action = "toggle" }))

bindMod("left", hl.dsp.focus({ direction = "left" }))
bindMod("right", hl.dsp.focus({ direction = "right" }))
bindMod("up", hl.dsp.focus({ direction = "up" }))
bindMod("down", hl.dsp.focus({ direction = "down" }))

-- Home-row workspaces; digits use keycodes so they work regardless of layout.
local workspaceKeys = { "a", "s", "d", "f", "g", "h", "j", "k", "l" }
for ws, key in ipairs(workspaceKeys) do
  bindMod(key, hl.dsp.focus({ workspace = ws }))
  bindMod("SHIFT + " .. key, hl.dsp.window.move({ workspace = ws, follow = true }))
  bindMod("SHIFT + code:" .. (ws + 9), hl.dsp.window.move({ workspace = ws, follow = true }))
end

bindMod("SHIFT + p", hl.dsp.global("com.t3tools.T3Code:capture-window"))

bindMod("mouse:272", hl.dsp.window.drag(), { mouse = true })
bindMod("mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("Print", hl.dsp.exec_cmd("hyprquickframe"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("env HQF_MODE=window hyprquickframe"))
bindMod("Print", hl.dsp.exec_cmd("env HQF_ACTION=edit hyprquickframe"))

local hardwareKey = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), hardwareKey)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), hardwareKey)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), hardwareKey)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), hardwareKey)
