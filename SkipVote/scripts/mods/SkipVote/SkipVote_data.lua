local mod = get_mod("SkipVote")

return {
	name = "SkipVote",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "skip_keybind",
				type = "keybind",
				keybind_global = true,
				keybind_type = "function_call",
				keybind_trigger = "pressed",
				function_name = "skip_vote",
				default_value = {}
			},

			{
				setting_id = "cancel_keybind",
				type = "keybind",
				keybind_global = true,
				keybind_type = "function_call",
				keybind_trigger = "pressed",
				function_name = "cancel_vote",
				default_value = {}
			},
		},
	},
}
