local mod = get_mod("debug-mode")

-- Re-enable the DebugDrawerRelease drawer
mod:dofile("scripts/mods/debug-mode/debug-drawer")
-- A copy of the debug_draw_slots from ai_slot_system.lua
local debug_slots = mod:dofile("scripts/mods/debug-mode/game-code/debug-slots")

-- save some time and default this stuff
script_data.debug_enabled = true
script_data.force_debug_disabled = false
script_data.disable_debug_draw = false
script_data.debug_key_handler_visible = true
Development._hardcoded_dev_params.force_debug_disabled = false
Development._hardcoded_dev_params.disable_debug_draw = false
Development._hardcoded_dev_params.debug_key_handler_visible = true

-- Stripped from release, needs to be redefined.
-- It should map consideration tables to names but /shrug
UtilityConsiderationNames = {}

-- Close the debug stuff when entering a loading screen
mod:hook_safe(StateLoading, "on_enter", function()
	Debug.active = false
	DebugScreen.active = false
	DebugKeyHandler.enabled = false
	Managers.input:device_unblock_all_services("keyboard", 1)
	Managers.input:device_unblock_all_services("mouse", 1)
end)

function mod:toggle_debug()
	local active = not Debug.active
	mod:echo("Debug enabled: %s", active)
	Debug.active = active
	DebugKeyHandler.enabled = active

	local debug_key_input_manager = DebugKeyHandler.input_manager:get_service("Debug")
	if debug_key_input_manager then
		if active then
			Managers.input:device_unblock_service("keyboard", 1, "Debug")
			Managers.input:device_unblock_service("mouse", 1, "Debug")
		else
			Managers.input:device_block_service("keyboard", 1, "Debug")
			Managers.input:device_block_service("mouse", 1, "Debug")
		end
	else
		mod:echo("NOT got Debug input_service")
	end
end

mod:hook_safe(Boot, "game_update", function(self, real_world_dt)
	local dt = Managers.time:scaled_delta_time(real_world_dt)
	local t = Managers.time:time("main")
	local input_manager = Managers.input
	local input_service = input_manager:get_service("DebugMenu")

	if Managers.state.debug_text then
		Managers.state.debug_text:clear_world_text()
		Managers.state.debug_text:clear_unit_text()
	end

	if Debug.enabled then
		Debug.update(t, dt)
	end
	DebugKeyHandler.current_y = 1000
	DebugKeyHandler.render()
	DebugScreen.update(dt, t, input_service, input_manager)

	if Managers.state.entity then
		local health_system = Managers.state.entity:system("health_system")
		local ai_system = Managers.state.entity:system("ai_system")

		health_system:update_debug()

		if ai_system.ai_debugger then
			ai_system.ai_debugger:update(dt, t)
			if ai_system.ai_debugger.show_slots then
				local t = Managers.time:time("main")
				local ai_slot_system = Managers.state.entity:system("ai_slot_system")
				local target_units = ai_slot_system.target_units
				local unit_extension_data = ai_slot_system.unit_extension_data
				local nav_world = ai_slot_system.nav_world
				debug_slots(target_units, unit_extension_data, nav_world, t)
			end
		end
	end

	if Managers.state.conflict then
		if Managers.state.conflict.level_analysis then
			Managers.state.conflict.level_analysis:debug(t)
		end
		Managers.state.conflict.debug_breed_picker = {
			update = function() end,
			current_item_name = function()
				return ""
			end,
		}
		Managers.state.conflict:update_server_debug(t, dt)
	end

	if Managers.state.debug then
		-- Don't do this because they dont show for some reason
		-- Managers.state.debug:update(dt, t)
		for _, drawer in pairs(Managers.state.debug._drawers) do
			drawer:update(Managers.state.debug._world)
		end
	end
end)

LevelAnalysis.debug = function(self, t)
	local debug_text = Managers.state.debug_text

	debug_text:clear_world_text("boss")

	-- Fixed conditional
	if true then
		local terror_spawners = self.terror_spawners
		local th = 0

		for name, data in pairs(terror_spawners) do
			local h = Vector3(0, 0, 22 + th)
			local spawners = data.spawners

			for i = 1, #spawners, 1 do
				local spawner = spawners[i]
				local unit = spawner[1]
				local map_section_index = spawner[3]
				local pos1 = Unit.local_position(unit, 0)
				local pos2 = pos1 + h
				local c = Colors.distinct_colors_lookup[(map_section_index + 3) % 10]
				local color = Color(c[1], c[2], c[3])

				QuickDrawerStay:line(pos1, pos2, color)
				debug_text:output_world_text(
					name,
					0.5,
					pos2,
					nil,
					"boss_spawning",
					Vector3(c[1], c[2], c[3]),
					"player_1"
				)

				local wanted_distance = spawner[2]
				local main_path_pos = MainPathUtils.point_on_mainpath(self.main_paths, wanted_distance)

				QuickDrawerStay:line(pos2, main_path_pos, color)
			end

			th = th + 0.5
		end

		self._debug_boss_spawning = true
	end

	if self.path_markers then
		for i = 1, #self.path_markers, 1 do
			local pos = self.path_markers[i].pos:unbox()

			if self.path_markers[i].marker_type == "break" or self.path_markers[i].marker_type == "crossroad_break" then
				QuickDrawer:cylinder(pos, pos + Vector3(0, 0, 8), 0.6, Color(255, 194, 13, 17), 16)
				QuickDrawer:sphere(pos + Vector3(0, 0, 8), 0.4, Color(255, 194, 13, 17))
			else
				QuickDrawer:cylinder(pos, pos + Vector3(0, 0, 8), 0.8, Color(255, 244, 183, 7), 16)
			end
		end
	end

	for k = 1, #self.main_paths, 1 do
		local main_path = self.main_paths[k]
		local nodes = main_path.nodes
		local path_length = main_path.path_length

		if nodes and #nodes > 0 then
			local last_pos = nodes[1]:unbox()

			for i = 1, #nodes, 1 do
				local pos = nodes[i]:unbox()

				QuickDrawer:sphere(pos + Vector3(0, 0, 1.5), 0.4, Color(255, 44, 143, 7))
				QuickDrawer:line(pos + Vector3(0, 0, 1.5), last_pos + Vector3(0, 0, 1.5), Color(255, 44, 143, 7))

				last_pos = pos
			end

			local pos, text = nil

			if self.boss_event_list then
				for i = 1, #self.boss_event_list, 1 do
					local data = self.boss_event_list[i]
					pos = data[1]:unbox()
					text = data[2]
					local pos_up = pos + Vector3(0, 0, 10)
					local color_name = data[4]
					local color = Colors.get(color_name)

					QuickDrawer:cylinder(pos, pos_up, 0.5, color, 10)
					QuickDrawer:sphere(pos_up, 2, color)

					local c = Colors.color_definitions[color_name]

					debug_text:output_world_text(text, 0.5, pos_up, nil, "boss", Vector3(c[2], c[3], c[4]), "player_1")
				end
			end

			local p = t % 5 / 5
			local point = LevelAnalysis.get_path_point(nodes, path_length, p)

			QuickDrawer:sphere(point + Vector3(0, 0, 1.5), 0.366, Color(255, 244, 183, 7))
		end
	end
end

-- Fix for gui created with missing font packages
mod:hook(SpawnZoneBaker, "draw_zone_info_on_screen", function(func, self)
	self._gui = World.create_screen_gui(self.world, "material", "materials/fonts/gw_fonts", "immediate")
	func(self)
end)

mod:hook(DebugKeyHandler, "key_pressed", function(func, key, description, category, key_modifier, input_service_name)
	if input_service_name == "FreeFlight" then
		return func(key, description, category, key_modifier, "Debug")
	else
		return func(key, description, category, key_modifier, input_service_name)
	end
end)
