-- luacheck: globals Unit get_mod
local mod = get_mod("UnitExplorer")

function mod.handle_inputs()
	if Keyboard.pressed(Keyboard.button_index("f2")) then
		if mod.outlined_unit and not Unit.alive(mod.outlined_unit) then
			mod.outlined_unit = nil
		end

		if mod.unit_explorer then
			local outline_system = Managers.state.entity:system("outline_system")

			local world = Managers.world:world("level_world")
			local physics_world = World.get_data(world, "physics_world")

			local player_unit = Managers.player:local_player().player_unit
			local first_person_extension = ScriptUnit.extension(player_unit, "first_person_system")
			local camera_position = first_person_extension:current_position()
			local camera_rotation = first_person_extension:current_rotation()
			local camera_forward = Quaternion.forward(camera_rotation)
			local distance = 15999
			local hits = physics_world:immediate_raycast(
				camera_position,
				camera_forward,
				distance,
				"all",
				"collision_filter",
				"filter_lookat_object_ray"
			)

			local closest_unit_hit = nil
			local closest_hit = 9999
			for _, hit in ipairs(hits) do
				local hit_distance = hit[2]
				local actor = hit[4]
				local unit = Actor.unit(actor)
				if unit ~= player_unit and hit_distance <= closest_hit then
					closest_hit = hit_distance
					closest_unit_hit = unit
				end
			end

			local flag = "outline_unit"
			local channel = Color(255, 0, 0, 255)
			local apply_method = "unit_and_childs"

			if closest_unit_hit == mod.outlined_unit and closest_unit_hit ~= nil then
				if mod.unit_explorer._is_open then
					mod.unit_explorer:close()
				end
				local do_outline = false
				outline_system:outline_unit(closest_unit_hit, flag, channel, do_outline, apply_method)
				mod.outlined_unit = nil
			elseif closest_unit_hit == nil then
				-- nothing
			else
				mod.unit_explorer:open(closest_unit_hit)
				local do_outline = true
				if mod.outlined_unit then
					outline_system:outline_unit(mod.outlined_unit, flag, channel, not do_outline, apply_method)
				end
				outline_system:outline_unit(closest_unit_hit, flag, channel, do_outline, apply_method)
				mod.outlined_unit = closest_unit_hit
				mod.dragged_rotation = QuaternionBox(Unit.local_rotation(mod.outlined_unit, 0))
			end
		end
	end

	if Keyboard.pressed(Keyboard.button_index("f3")) then
		if mod.level_explorer then
			mod.level_explorer:toggle()
		end
	end

	if Keyboard.pressed(Keyboard.button_index("home")) then
		mod.dragging = not mod.dragging

		if mod.dragging then
			local player_manager = Managers.player
			local local_player = player_manager:local_player()
			local viewport_name = local_player.viewport_name
			local camera_position = Managers.state.camera:camera_position(viewport_name)
			local unit_position = Unit.local_position(mod.outlined_unit, 0)
			mod.dragged_unit_distance = Vector3.distance(camera_position, unit_position)
		end
	end

	if mod.dragging then
		local scroll = Vector3.y(Mouse.axis(Mouse.axis_id("wheel")))
		mod.dragged_unit_distance = mod.dragged_unit_distance + scroll
	end

	if Keyboard.pressed(Keyboard.button_index("r")) then
		mod.rotating = true
	end
	if Keyboard.released(Keyboard.button_index("r")) then
		mod.rotating = false
	end
end
