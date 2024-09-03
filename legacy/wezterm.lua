-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
-- config.font = wezterm.font('JetBrainsMono')
config.front_end = "WebGpu"

-- config.window_decorations = 'NONE'
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

-- Changing the color scheme:
config.color_scheme = 'tokyonight'

-- and finally, return the configuration to wezterm
return config
