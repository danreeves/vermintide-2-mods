-- luacheck: globals get_mod LevelSettings Managers NetworkLookup PackageManager LevelResource Level World AdventureSpawning
local mod = get_mod("TestLevel")

local level_name = "test_level"
local level_package_name = "resource_packages/TestLevel/test_level"

LevelSettings[level_name] = {
	conflict_settings = "level_editor",
	no_terror_events = true,
	package_name = level_package_name,
	player_aux_bus_name = "environment_reverb_outside",
	environment_state = "exterior",
	knocked_down_setting = "knocked_down",
	ambient_sound_event = "silent_default_world_sound",
	level_name = "content/levels/test_level",
	level_image = "level_image_any",
	loading_ui_package_name = "loading_screen_1",
	display_name = "test_level",
	source_aux_bus_name = "environment_reverb_outside_source",
	level_particle_effects = {},
	level_screen_effects = {},
	locations = {}
}

local id = #NetworkLookup.level_keys + 1
NetworkLookup.level_keys[id] = level_name
NetworkLookup.level_keys[level_name] = id

mod:command("test_level", "Load into the test level", function()
	Managers.state.game_mode:start_specific_level("test_level")
end)

mod:hook(PackageManager, "load", function (func, self, package_name, reference_name, callback, asynchronous, prioritize)
	if package_name == level_package_name then
		-- Load the keep in sync with out package because we use it's shading environment
		Managers.package:load("resource_packages/levels/inn", "TestLevel", nil, true)
		return mod:load_package(package_name)
	else
		return func(self, package_name, reference_name, callback, asynchronous, prioritize)
	end
end)

mod:hook(PackageManager, "has_loaded", function (func, self, package_name, reference_name)
	if package_name == level_package_name then
		-- Load the keep in sync with out package because we use it's shading environment
		local inn_loaded = Managers.package:has_loaded("resource_packages/levels/inn", "TestLevel")
		return inn_loaded and mod:package_status(package_name) == "loaded"
	else
		return func(self, package_name, reference_name)
	end
end)

mod:hook(PackageManager, "unload", function (func, self, package_name, reference_name)
	if package_name == level_package_name then
		-- Unload the keep in sync with out package because we use it's shading environment
		Managers.package:unload("resource_packages/levels/inn", "TestLevel")
		return mod:unload_package(package_name)
	else
		return func(self, package_name, reference_name)
	end
end)

mod:hook(LevelResource, "nested_level_count", function(func, target_level_name)
	-- For some reason this was erroring about the level not being loaded yet
	if target_level_name == level_name then
		return 0
	else
		return func(target_level_name)
	end
end)

mod:hook(Level, "get_data", function(func, level, key)
	local result = func(level, key)
	if key == "shading_environment" and result == nil then
		-- Use the keeps shading environment because we don't have our own yet
		return "environment/honduras_keep_02"
	end
	return result
end)

mod:hook(AdventureSpawning, "get_spawn_point", function(func, self)
	local game_mode = Managers.state.game_mode
	local default_state = "default"
	local prior_state = Managers.mechanism:get_prior_state() or default_state
	local spawn_points = self._spawn_points[prior_state] or self._spawn_points[default_state]

	if spawn_points == nil then
		local world = Managers.world:world("level_world")
		local spawners = World.units_by_resource(world, "content/models/props/spawner")

		for _, unit in ipairs(spawners) do
			if game_mode then
				game_mode:flow_callback_add_spawn_point(unit)
			end
		end
	end

	return func(self)
end)

mod:command("load", "", function()
	Managers.package:load("resource_packages/breeds/skaven", "TestLevel", function()
		mod:echo("loaded")
	end)
end)
