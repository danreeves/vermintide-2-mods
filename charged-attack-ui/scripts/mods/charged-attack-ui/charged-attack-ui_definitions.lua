local scenegraph_definition = {
	root = {
		is_root = true,
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
	screen = {
		scale = "fit",
		position = {
			0,
			0,
			UILayer.hud,
		},
		size = {
			1920,
			1080,
		},
	},
}

local widget_definition = {
	scenegraph_id = "screen",
	element = {
		passes = {
			{
				style_id = "charged_level_text",
				pass_type = "text",
				text_id = "charged_level_text",
				retained_mode = false,
				fade_out_duration = 5,
				content_check_function = function(content)
					return content.is_charging
				end,
			},
		},
	},
	content = {
		charged_level_text = "HELLO",
		is_charging = false,
	},
	style = {
		charged_level_text = {
			font_type = "hell_shark",
			font_size = 32,
			vertical_alignment = "center",
			horizontal_alignment = "center",
			text_color = Colors.get_table("white"),
			offset = {
				100,
				0,
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

return {
	scenegraph_definition = scenegraph_definition,
	widget_definition = widget_definition,
}
