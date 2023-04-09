-- luacheck: globals get_mod
local mod = get_mod("ComicSans")

return {
	name = "Comic Sans",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "font",
				type = "dropdown",
				default_value = "ComicSans",
				options = {
					{ text = "ComicSans", value = "ComicSans" },
					{ text = "Queekish", value = "Queekish" },
				},
			},
		},
	},
}
