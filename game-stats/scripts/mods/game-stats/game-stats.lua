local mod = get_mod("game-stats")
local simple_ui = get_mod("SimpleUI")

--[[
  Simple UI fix
  The close button is incorrectly positioned.
  See: https://github.com/Vermintide-Mod-Framework/Grasmann-Mods/pull/11
--]]
simple_ui.widgets.window.create_close_button = function(self, name, params)
	local widget = self:create_widget(name, { 5, 0 }, { 25, 25 }, "close_button", "top_right", params)
	widget:set("text", "X")
	self:add_widget(widget)
	return widget
end

-- Data
mod:dofile("scripts/mods/game-stats/constants")
mod:dofile("scripts/mods/game-stats/interesting-stats")
-- Helper functions
mod:dofile("scripts/mods/game-stats/utils")
-- UI logic
mod:dofile("scripts/mods/game-stats/ui")
-- Chat command logic
mod:dofile("scripts/mods/game-stats/commands")

-- Called by the hotkey set up in VMF options
mod.toggle_with_hotkey = function()
	mod.toggle_window()
end

return
