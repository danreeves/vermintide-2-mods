local mod = get_mod("GoToLevel")

return {
	name = "Restart Level",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "go_to_level_enabled",
				type = "checkbox",
				default_value = false,
				tooltip = "go_to_level_enabled_tooltip",
			},
		},
	},
}
