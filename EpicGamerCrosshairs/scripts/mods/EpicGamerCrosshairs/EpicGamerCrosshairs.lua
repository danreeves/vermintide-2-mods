-- luacheck: globals get_mod Managers World CrosshairUI ScriptGUI Vector2 Color UIResolution UILayer
local mod = get_mod("EpicGamerCrosshairs")

-- Cache for mod settings
local config = {}

function mod.get_config()
	config = {
		gap = mod:get("gap"),
		thickness = mod:get("thickness"),
		size = mod:get("size"),
		r = mod:get("color_r"),
		g = mod:get("color_g"),
		b = mod:get("color_b"),
		a = mod:get("color_a"),
		show_dot = mod:get("show_dot"),
		disable_default_crosshairs = mod:get("disable_default_crosshairs"),
	}
end

-- Init config cache
mod.get_config()

-- Update config cache when settings change
function mod.on_setting_changed()
	mod.get_config()
end

function mod.init()
	mod.get_config()
	mod.world = Managers.world:world("top_ingame_view")
	mod.gui = World.create_screen_gui(mod.world, "material", "materials/fonts/gw_fonts", "immediate")
end

mod:hook_safe(CrosshairUI, "init", function()
	mod.init()
end)

mod:hook(CrosshairUI, "update", function(func, self, ...)
	-- In case the mod is enabled after the CrosshairUI has init
	if not mod.gui then
		mod.init()
	end

	local screen_w, screen_h = UIResolution()
	local mid_x = screen_w / 2
	local mid_y = screen_h / 2

	local gap = config.gap
	local thickness = config.thickness
	local size = config.size
	local color = Color(config.a, config.r, config.g, config.b)

	local up1 = Vector2(mid_x + (thickness / 2), mid_y + gap)
	local up2 = Vector2(mid_x + (thickness / 2), mid_y + gap + size)

	local down1 = Vector2(mid_x - (thickness / 2), mid_y - gap)
	local down2 = Vector2(mid_x - (thickness / 2), mid_y - gap - size)

	local left1 = Vector2(mid_x - gap, mid_y + (thickness / 2))
	local left2 = Vector2(mid_x - gap - size, mid_y + (thickness / 2))

	local right1 = Vector2(mid_x + gap, mid_y - (thickness / 2))
	local right2 = Vector2(mid_x + gap + size, mid_y - (thickness / 2))

	ScriptGUI.hud_line(mod.gui, up1, up2, UILayer.hud, thickness, color)
	ScriptGUI.hud_line(mod.gui, down1, down2, UILayer.hud, thickness, color)
	ScriptGUI.hud_line(mod.gui, left1, left2, UILayer.hud, thickness, color)
	ScriptGUI.hud_line(mod.gui, right1, right2, UILayer.hud, thickness, color)

	if config.show_dot then
		local center1 = Vector2(mid_x + (thickness / 2), mid_y + (thickness / 2))
		local center2 = Vector2(mid_x - (thickness / 2), mid_y + (thickness / 2))
		ScriptGUI.hud_line(mod.gui, center1, center2, UILayer.hud, thickness, color)
	end

	if not config.disable_default_crosshairs then
		func(self, ...)
	end
end)
