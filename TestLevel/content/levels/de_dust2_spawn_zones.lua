-- luacheck: globals get_mod
local mod = get_mod("TestLevel")

mod:echo("[test_level loaded]")

return {
	version = "1",
	number_of_spawns = 0,
	path_markers = {},
	zones = {},
	cover_points = {},
	num_main_zones = 0,
	position_lookup = {},
	main_paths = {},
	crossroads = {},
	total_main_path_length = 0,
}
