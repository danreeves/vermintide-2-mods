local mod = get_mod("weapon_debug")

return {
  name = "weapon_debug",
  description = mod:localize("mod_description"),
  is_togglable = true,
  options = {
	widgets = {
	  {
		setting_id      = "clear_lines",
		type            = "keybind",
		keybind_global  = true,
		keybind_trigger = "pressed",
		keybind_type    = "function_call",
		function_name   = "clear_lines",
		default_value   = {}
	  },
	  {
		setting_id = "only_show_latest_attack",
		type = "checkbox",
		default_value = true,
	  },
	},
  },
}
