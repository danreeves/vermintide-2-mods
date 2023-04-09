local mod = get_mod("is-dwons-on")

return {
	name = "DwOns QoL",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "x",
				type = "numeric",
				default_value = 0,
				range = { -960, 960 },
			},
			{
				setting_id = "y",
				type = "numeric",
				default_value = -400,
				range = { -540, 540 },
			},
			{
				setting_id = "font_size",
				type = "numeric",
				default_value = 32,
				range = { 0, 360 },
			},
			{
				setting_id = "align_vertically",
				type = "checkbox",
				default_value = false,
				sub_widgets = {
					{
						setting_id = "horizontal_alignment",
						type = "dropdown",
						default_value = "left",
						options = {
							{ text = "left", value = "left" },
							{ text = "right", value = "right" },
							{ text = "center", value = "center" },
						},
					},
				},
			},
			{
				setting_id = "enable_on_boot",
				type = "checkbox",
				default_value = false,
			},
		},
	},
}
