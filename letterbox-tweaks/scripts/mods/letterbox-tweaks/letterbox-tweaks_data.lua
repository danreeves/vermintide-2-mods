local mod = get_mod("letterbox-tweaks")

return {
	name = "Letterbox tweaks",
	description = mod:localize("mod_description"),
	is_togglable = true,
	is_mutator = false,
	mutator_settings = {},
	options = {
		widgets = {
			{
				setting_id = "letterbox_disabled",
				type = "checkbox",
				title = "letterbox_disabled_title",
				tooltip = "letterbox_disabled_tooltip",
				default_value = false,
			},
			{
				setting_id = "letterbox_height",
				type = "numeric",
				title = "letterbox_height_title",
				tooltip = "letterbox_height_tooltip",
				default_value = 70,
				range = { 0, 500 },
			},
		},
	},
}
