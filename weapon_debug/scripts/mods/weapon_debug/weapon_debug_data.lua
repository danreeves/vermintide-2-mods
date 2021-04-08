local mod = get_mod("weapon_debug")

return {
  name = "Hitbox Debugger",
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
		setting_id      = "timescale_up",
		type            = "keybind",
		keybind_global  = true,
		keybind_trigger = "pressed",
		keybind_type    = "function_call",
		function_name   = "timescale_up",
		default_value   = {}
	  },
	  {
		setting_id      = "timescale_down",
		type            = "keybind",
		keybind_global  = true,
		keybind_trigger = "pressed",
		keybind_type    = "function_call",
		function_name   = "timescale_down",
		default_value   = {}
	  },
	  {
		setting_id = "show_attack_boxes",
		type = "checkbox",
		default_value = true,
	  },
	  {
		setting_id = "only_show_latest_attack",
		type = "checkbox",
		default_value = true,
	  },
	  {
		setting_id = "show_enemy_attacks",
		type = "checkbox",
		default_value = false,
	  },
	},
  },
}
