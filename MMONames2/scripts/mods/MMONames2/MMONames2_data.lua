-- luacheck: globals get_mod
local mod = get_mod("MMONames2")

return {
	name = "MMONames2",
	description = mod:localize("mod_description"),
	is_togglable = true,
	custom_gui_textures = {
		atlases = {
			{
				"atlases/mods/MMONames2/store_copy",
				"store_copy",
			},
		},
		ui_renderer_injections = {
			{
				"ingame_ui",
				"materials/mods/MMONames2/store_copy",
			},
		},
	},
	options = {
		widgets = {
			{
				setting_id = "font_size_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "font",
						type = "dropdown",
						default_value = 1,
						options = {
							{ text = "hell_shark_body", value = 1 },
							{ text = "hell_shark_header", value = 2 },
							{ text = "arial", value = 3 },
						},
					},
					{
						setting_id = "min_font_size",
						type = "numeric",
						default_value = 10,
						range = { 1, 255 },
					},
					{
						setting_id = "max_font_size",
						type = "numeric",
						default_value = 20,
						range = { 1, 255 },
					},
				},
			},
			{
				setting_id = "render_distance_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "min_render_distance",
						type = "numeric",
						default_value = 0,
						range = { 0, 1000 },
					},
					{
						setting_id = "max_render_distance",
						type = "numeric",
						default_value = 255,
						range = { 0, 1000 },
					},
				},
			},
			{
				setting_id = "group_user_color_specific_name_not_to_match_children_startswith",
				type = "group",
				sub_widgets = {
					{
						setting_id = "user_color_r",
						type = "numeric",
						default_value = 255,
						range = { 0, 255 },
					},
					{
						setting_id = "user_color_g",
						type = "numeric",
						default_value = 255,
						range = { 0, 255 },
					},
					{
						setting_id = "user_color_b",
						type = "numeric",
						default_value = 255,
						range = { 0, 255 },
					},
				},
			},
			{
				setting_id = "misc_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "show_name",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "show_career_icon",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "show_health",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "text_shadow",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "transparent_at_distance",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "display_own_name",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "color_override",
						type = "checkbox",
						default_value = false,
					},
				},
			},
		},
	},
}
