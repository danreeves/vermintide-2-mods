local mod = get_mod("wikitool")

local show_stamina_ui = mod:get("show_stamina_ui")
function mod.on_setting_changed()
	show_stamina_ui = mod:get("show_stamina_ui")
end

local fake_input_service = {
	get = function()
		return
	end,
	has = function()
		return
	end,
}

local scenegraph_definition = {
	root = {
		scale = "fit",
		size = {
			1920,
			1080,
		},
		position = {
			0,
			0,
			UILayer.hud,
		},
	},
}

local stamina_ui_definition = {
	scenegraph_id = "root",
	element = {
		passes = {
			{
				style_id = "stamina_text",
				pass_type = "text",
				text_id = "stamina_text",
				retained_mode = false,
				fade_out_duration = 5,
				content_check_function = function(content)
					return true
				end,
			},
			{
				style_id = "other_text",
				pass_type = "text",
				text_id = "other_text",
				retained_mode = false,
				content_check_function = function(content)
					return true
				end,
			},
			{
				style_id = "line_3",
				pass_type = "text",
				text_id = "line_3",
				retained_mode = false,
				content_check_function = function(content)
					return true
				end,
			},
		},
	},
	content = {
		stamina_text = "",
		other_text = "",
		line_3 = "",
	},
	style = {
		stamina_text = {
			font_type = "hell_shark",
			font_size = 42,
			vertical_alignment = "center",
			horizontal_alignment = "center",
			text_color = Colors.get_table("white"),
			offset = {
				0,
				0,
				0,
			},
		},
		other_text = {
			font_type = "hell_shark",
			font_size = 36,
			vertical_alignment = "center",
			horizontal_alignment = "center",
			text_color = Colors.get_table("white"),
			offset = {
				0,
				-36,
				0,
			},
		},
		line_3 = {
			font_type = "hell_shark",
			font_size = 36,
			vertical_alignment = "center",
			horizontal_alignment = "center",
			text_color = Colors.get_table("white"),
			offset = {
				0,
				-(36 * 2),
				0,
			},
		},
	},
	offset = {
		0,
		0,
		0,
	},
}

function mod:init_stamina_ui()
	if mod.ui_widget then
		return
	end

	local world = Managers.world:world("top_ingame_view")
	mod.ui_renderer = UIRenderer.create(world, "material", "materials/fonts/gw_fonts")
	mod.ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
	mod.ui_widget = UIWidget.init(stamina_ui_definition)
end

mod:hook(GenericStatusExtension, "update", function(func, self, unit, input, dt, context, t)
	if not show_stamina_ui or not self.fatigue or not self.max_fatigue_points then
		-- oops
		return func(self, unit, input, dt, context, t)
	end

	if not mod.ui_widget then
		mod.init_stamina_ui()
	end

	local widget = mod.ui_widget
	local ui_renderer = mod.ui_renderer
	local ui_scenegraph = mod.ui_scenegraph

	local max_fatigue = PlayerUnitStatusSettings.MAX_FATIGUE
	local max_fatigue_points = self.max_fatigue_points

	local degen_delay = self.block_broken_degen_delay
		or self.push_degen_delay
		or PlayerUnitStatusSettings.FATIGUE_DEGEN_DELAY
	degen_delay = degen_delay / self.buff_extension:apply_buffs_to_value(1, "fatigue_regen")

	local current, max =
		(max_fatigue_points == 0 and 0) or (self.fatigue / (max_fatigue / max_fatigue_points)), max_fatigue_points

	local degen_amount = (max_fatigue_points == 0 and 0)
		or PlayerUnitStatusSettings.FATIGUE_POINTS_DEGEN_AMOUNT
			/ max_fatigue_points
			* PlayerUnitStatusSettings.MAX_FATIGUE
	local new_degen_amount = self.buff_extension:apply_buffs_to_value(degen_amount, "fatigue_regen")

	local cooldown = t - self.last_fatigue_gain_time < degen_delay
			and math.abs(t - self.last_fatigue_gain_time - degen_delay)
		or 0

	widget.content.stamina_text = string.format("Stamina: %.1f", max - current)
	widget.content.other_text = string.format("Regen delay: %.1fs | Regen amount: %.1f", cooldown, new_degen_amount)
	widget.content.line_3 = string.format("Regen delay: %.1fs", degen_delay)

	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, fake_input_service, dt)
	UIRenderer.draw_widget(ui_renderer, widget)
	UIRenderer.end_pass(ui_renderer)

	return func(self, unit, input, dt, context, t)
end)
