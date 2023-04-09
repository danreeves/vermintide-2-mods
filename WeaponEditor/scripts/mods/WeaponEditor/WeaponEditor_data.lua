-- luacheck: globals get_mod
local mod = get_mod("WeaponEditor")

return {
	name = "WeaponEditor",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "open_window",
				type = "keybind",
				keybind_global = true,
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "toggle_ui",
				default_value = {},
			},
		},
	},
}
