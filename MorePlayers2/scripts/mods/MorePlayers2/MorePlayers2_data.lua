-- luacheck: globals get_mod
local mod = get_mod("MorePlayers2")

return {
	name = "[BETA] BTMP",
	description = mod:localize("mod_description"),
	is_togglable = false,
	custom_gui_textures = {
		atlases = {
			{
				"atlases/mods/MorePlayers2/store_copy",
				"moreplayers2_store_copy",
			},
		},
		ui_renderer_injections = {
			{
				"ingame_ui",
				"materials/mods/MorePlayers2/store_copy",
			},
		},
	},
	options = {
		widgets = {
			{
				setting_id = "show_player_list",
				type = "checkbox",
				default_value = true,
				sub_widgets = {
					{
						setting_id = "use_default_player_list",
						type = "checkbox",
						default_value = false,
					},
				},
			},
			{
				setting_id = "font",
				type = "dropdown",
				default_value = 2,
				options = {
					{ text = "arial", value = 1 },
					{ text = "hell_shark_body", value = 2 },
					{ text = "hell_shark_header", value = 3 },
				},
			},
			{
				setting_id = "font_size",
				type = "numeric",
				range = { 0, 255 },
				default_value = 18,
			},
			{
				setting_id = "use_mmo_names_colors",
				type = "checkbox",
				default_value = false,
			},
			{
				setting_id = "show_hp",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_healing_items",
				type = "checkbox",
				default_value = false,
			},
			{
				setting_id = "show_books",
				type = "checkbox",
				default_value = false,
			},
			{
				setting_id = "show_pots",
				type = "checkbox",
				default_value = false,
			},
			{
				setting_id = "show_bombs",
				type = "checkbox",
				default_value = false,
			},
			{
				setting_id = "num_bots",
				type = "numeric",
				default_value = 0,
				range = { 0, 8 },
			},
			{
				setting_id = "max_players",
				type = "numeric",
				default_value = 32,
				range = { 1, 32 },
			},
		},
	},
}
