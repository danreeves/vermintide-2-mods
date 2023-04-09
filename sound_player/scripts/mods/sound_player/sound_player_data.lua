local mod = get_mod("sound_player")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	options = {
		widgets = {
			{
				setting_id = "open_sound_player",
				type = "keybind",
				default_value = {},
				keybind_trigger = "pressed",
				keybind_type = "view_toggle",
				view_name = "sound_player_view",
				transition_data = {
					open_view_transition_name = "open_sound_player",
					close_view_transition_name = "close_sound_player",
				},
			},
			{
				setting_id = "play_selected_sound",
				type = "keybind",
				default_value = {},
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "play_selected_sound",
			},
		},
	},
}
