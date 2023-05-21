local mod = get_mod("is-dwons-on")

function create_scenegraph_definition(x, y)
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
		pivot = {
			parent = "root",
			size = { 0, 0 },
			vertical_alignment = "center",
			horizontal_alignment = "center",
			position = {
				x,
				y,
				UILayer.hud,
			},
		},
	}
	return scenegraph_definition
end

function create_widget_definition()
	return {
		scenegraph_id = "pivot",
		element = {
			passes = {
				{
					pass_type = "text",
					style_id = "text",
					text_id = "text",
					retained_mode = false,
					content_check_function = function(content)
						return mod:is_at_inn() and mod:is_host_or_host_synced()
					end,
				},
			},
		},
		content = {
			text = "",
		},
		style = {
			text = {
				font_type = "hell_shark",
				font_size = mod:get("font_size"),
				vertical_alignment = "center",
				horizontal_alignment = "right",
				text_color = Colors.get_table("white"),
				offset = {
					0,
					0,
					0,
				},
			},
		},
	}
end

return {
	create_widget_definition = create_widget_definition,
	create_scenegraph_definition = create_scenegraph_definition,
}
