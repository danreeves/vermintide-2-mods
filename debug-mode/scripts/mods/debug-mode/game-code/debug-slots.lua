-- luacheck: globals Managers Vector3 Colors AiUtils ALIVE SlotTypeSettings POSITION_LOOKUP Unit Quaternion GwNavQueries Color Debug get_mod

local unit_alive = AiUtils.unit_alive
local SLOT_STATUS_UPDATE_INTERVAL = 0.5
local PENALTY_TERM = 100
local MIN_WAIT_QUEUE_DISTANCE = 3
local MAX_QUEUE_Z_DIFF_ABOVE = 2
local MAX_QUEUE_Z_DIFF_BELOW = 3
local SLOT_RADIUS = 0.5
local SLOT_POSITION_CHECK_INDEX = {
	CHECK_LEFT = 0,
	CHECK_RIGHT = 2,
	CHECK_MIDDLE = 1,
}
local SLOT_POSITION_CHECK_RADIANS = {
	[SLOT_POSITION_CHECK_INDEX.CHECK_LEFT] = math.degrees_to_radians(-90),
	[SLOT_POSITION_CHECK_INDEX.CHECK_RIGHT] = math.degrees_to_radians(90),
}
local Vector3_distance_sq = Vector3.distance_squared
local Vector3_distance = Vector3.distance
local Vector3_copy = Vector3.copy
local Vector3_normalize = Vector3.normalize
local Vector3_flat = Vector3.flat
local GwNavQueries_triangle_from_position = GwNavQueries.triangle_from_position
local GwNavQueries_raycango = GwNavQueries.raycango
local SLOT_QUEUE_RADIUS = 1.75
local Z_MAX_DIFFERENCE_ABOVE = 1.5
local Z_MAX_DIFFERENCE_BELOW = 1.5
local NAVMESH_DISTANCE_FROM_WALL = 0.5
local MOVER_RADIUS = 0.6
local RAYCANGO_OFFSET = NAVMESH_DISTANCE_FROM_WALL + MOVER_RADIUS
local Quaternion_rotate = Quaternion.rotate

local function rotate_position_from_origin(origin, position, radians, distance)
	local direction_vector = Vector3_normalize(Vector3_flat(position - origin))
	local rotation = Quaternion(-Vector3.up(), radians)
	local vector = Quaternion_rotate(rotation, direction_vector)
	local position_rotated = origin + vector * distance

	return position_rotated
end

local function clamp_position_on_navmesh(position, nav_world, above, below)
	below = below or Z_MAX_DIFFERENCE_BELOW
	above = above or Z_MAX_DIFFERENCE_ABOVE
	local position_on_navmesh = nil
	local is_on_navmesh, altitude = GwNavQueries_triangle_from_position(nav_world, position, above, below)

	if is_on_navmesh then
		position_on_navmesh = Vector3_copy(position)
		position_on_navmesh.z = altitude
	end

	return (is_on_navmesh and position_on_navmesh) or nil
end

local function get_anchor_slot(slot_type, target_unit, unit_extension_data)
	local target_unit_extension = unit_extension_data[target_unit]
	local slot_data = target_unit_extension.all_slots[slot_type]
	local target_slots = slot_data.slots
	local total_slots_count = slot_data.total_slots_count
	local best_slot = target_slots[1]
	local best_anchor_weight = best_slot.anchor_weight

	for i = 1, total_slots_count, 1 do
		repeat
			local slot = target_slots[i]
			local slot_disabled = slot.disabled

			if slot_disabled then
				break
			end

			local slot_anchor_weight = slot.anchor_weight

			if
				best_anchor_weight < slot_anchor_weight
				or (slot_anchor_weight == best_anchor_weight and slot.index < best_slot.index)
			then
				best_slot = slot
				best_anchor_weight = slot_anchor_weight
			end
		until true
	end

	return best_slot
end

local function get_slot_queue_position(unit_extension_data, slot, nav_world, distance_modifier, t)
	local target_unit = slot.target_unit
	local ai_unit = slot.ai_unit

	if not unit_alive(target_unit) or not ALIVE[ai_unit] then
		return
	end

	local ai_unit_extension = unit_extension_data[ai_unit]
	local slot_template = ai_unit_extension.slot_template
	local slot_type = slot.type
	local slot_distance = SlotTypeSettings[slot_type].distance
	local target_unit_extension = unit_extension_data[target_unit]
	local all_slots_occupied_at_t = target_unit_extension.full_slots_at_t[slot_type]
	local min_wait_queue_distance = slot_template.min_wait_queue_distance or MIN_WAIT_QUEUE_DISTANCE
	local min_wait_queue_distance_sq = min_wait_queue_distance * min_wait_queue_distance
	local offset_distance = 0

	if all_slots_occupied_at_t and slot_template.min_queue_offset_distance then
		local min_queue_offset_distance = slot_template.min_queue_offset_distance
		local full_offset_at_t = slot_template.full_offset_time
		local t_diff = t - all_slots_occupied_at_t
		local queue_offset_scale = math.min(t_diff / full_offset_at_t, 1)
		offset_distance = min_queue_offset_distance * queue_offset_scale
	end

	local target_unit_position = target_unit_extension.position:unbox()
	local ai_unit_position = POSITION_LOOKUP[ai_unit]
	local slot_queue_direction = slot.queue_direction:unbox()
	local slot_queue_distance_modifier = distance_modifier or 0
	local target_to_ai_distance = Vector3_distance(target_unit_position, ai_unit_position)
	local queue_distance = SlotTypeSettings[slot_type].queue_distance
	local slot_queue_distance = math.max(
		(target_to_ai_distance + queue_distance + slot_queue_distance_modifier) - offset_distance,
		min_wait_queue_distance
	)
	local slot_queue_position = target_unit_position + slot_queue_direction * slot_queue_distance
	local slot_queue_position_on_navmesh = clamp_position_on_navmesh(
		slot_queue_position,
		nav_world,
		MAX_QUEUE_Z_DIFF_ABOVE,
		MAX_QUEUE_Z_DIFF_BELOW
	)
	local max_tries = 5
	local i = 1

	while not slot_queue_position_on_navmesh and i <= max_tries do
		slot_queue_distance = math.max(
			(
					math.max(target_to_ai_distance * (1 - i / max_tries), slot_distance)
					+ queue_distance
					+ slot_queue_distance_modifier
				) - offset_distance,
			min_wait_queue_distance
		)
		slot_queue_position = target_unit_position + slot_queue_direction * math.max(slot_queue_distance, 0.5)
		slot_queue_position_on_navmesh = clamp_position_on_navmesh(
			slot_queue_position,
			nav_world,
			MAX_QUEUE_Z_DIFF_ABOVE,
			MAX_QUEUE_Z_DIFF_BELOW
		)
		i = i + 1
	end

	local penalty_term = 0
	local can_go = nil

	if slot_queue_position_on_navmesh then
		local target_position_on_navmesh = clamp_position_on_navmesh(
			target_unit_position,
			nav_world,
			MAX_QUEUE_Z_DIFF_ABOVE,
			MAX_QUEUE_Z_DIFF_BELOW
		)

		if target_position_on_navmesh then
			can_go = GwNavQueries_raycango(nav_world, slot_queue_position_on_navmesh, target_position_on_navmesh)
		end
	end

	if not slot_queue_position_on_navmesh or not can_go then
		penalty_term = PENALTY_TERM
		slot_queue_position = target_unit_position + slot_queue_direction * queue_distance

		if slot_template.restricted_queue_distance then
			local slot_queue_distance_from_target_sq = Vector3_distance_sq(target_unit_position, slot_queue_position)

			if min_wait_queue_distance_sq <= slot_queue_distance_from_target_sq then
				return slot_queue_position, penalty_term
			else
				local fallback_queue_position_on_navmesh = nil
				local target_unit_to_ai_direction = Vector3_normalize(ai_unit_position - target_unit_position)
				local i = 1 -- luacheck: ignore

				while not fallback_queue_position_on_navmesh and i <= max_tries do
					slot_queue_distance = math.max(
						(
								math.max(target_to_ai_distance * (1 - i / max_tries), slot_distance)
								+ queue_distance
								+ slot_queue_distance_modifier
							) - offset_distance,
						min_wait_queue_distance
					)
					slot_queue_position = target_unit_position
						+ target_unit_to_ai_direction * math.max(slot_queue_distance, 0.5)
					fallback_queue_position_on_navmesh = clamp_position_on_navmesh(
						slot_queue_position,
						nav_world,
						MAX_QUEUE_Z_DIFF_ABOVE,
						MAX_QUEUE_Z_DIFF_BELOW
					)
					i = i + 1
				end

				if fallback_queue_position_on_navmesh then
					return fallback_queue_position_on_navmesh, 0
				else
					return slot_queue_position, penalty_term
				end
			end
		else
			return slot_queue_position, penalty_term
		end
	else
		return slot_queue_position_on_navmesh, penalty_term
	end
end

local function debug_draw_slots(target_units, unit_extension_data, nav_world, t) -- luacheck: ignore
	local drawer = Managers.state.debug:drawer({
		mode = "immediate",
		name = "AISlotSystem_immediate",
	})
	local z = Vector3.up() * 0.1
	local sides = Managers.state.side:sides()

	for j = 1, #sides, 1 do
		local side = sides[j]
		local targets = side.AI_TARGET_UNITS

		for i_target, target_unit in pairs(targets) do
			repeat
				if not unit_alive(target_unit) then
					break
				end

				local target_unit_extension = unit_extension_data[target_unit]

				if not target_unit_extension or not target_unit_extension.valid_target then
					break
				end

				local all_slots = target_unit_extension.all_slots

				for slot_type, slot_data in pairs(all_slots) do
					local target_slots = slot_data.slots
					local target_slots_n = #target_slots
					local target_position = target_unit_extension.position:unbox()
					local target_color = Colors.get(target_unit_extension.debug_color_name)

					drawer:circle(target_position + z, 0.5, Vector3.up(), target_color)
					drawer:circle(target_position + z, 0.45, Vector3.up(), target_color)

					if target_unit_extension.next_slot_status_update_at then
						local percent = (t - target_unit_extension.next_slot_status_update_at)
							/ SLOT_STATUS_UPDATE_INTERVAL

						drawer:circle(target_position + z, 0.45 * percent, Vector3.up(), target_color)
					end

					for i = 1, target_slots_n, 1 do
						repeat
							local slot = target_slots[i]
							local anchor_slot = get_anchor_slot(slot_type, target_unit, unit_extension_data)
							local is_anchor_slot = slot == anchor_slot
							local ai_unit = slot.ai_unit
							local alpha = (ai_unit and 255) or 150
							local color = (slot.disabled and Colors.get_color_with_alpha("gray", alpha))
								or Colors.get_color_with_alpha(slot.debug_color_name, alpha)

							if slot.absolute_position then
								local slot_absolute_position = slot.absolute_position:unbox()

								if ALIVE[ai_unit] then
									local ai_unit_position = POSITION_LOOKUP[ai_unit]

									drawer:circle(ai_unit_position + z, 0.35, Vector3.up(), color)
									drawer:circle(ai_unit_position + z, 0.3, Vector3.up(), color)

									local head_node = Unit.node(ai_unit, "c_head")
									local viewport_name = "player_1"
									local color_table = (slot.disabled and Colors.get_table("gray"))
										or Colors.get_table(slot.debug_color_name)
									local color_vector = Vector3(color_table[2], color_table[3], color_table[4])
									local offset_vector = Vector3(0, 0, -1)
									local text_size = 0.4
									local text = slot.index
									local category = "slot_index"

									Managers.state.debug_text:clear_unit_text(ai_unit, category)
									Managers.state.debug_text:output_unit_text(
										text,
										text_size,
										ai_unit,
										head_node,
										offset_vector,
										nil,
										category,
										color_vector,
										viewport_name
									)

									if slot.ghost_position.x ~= 0 and not slot.disable_at then
										local ghost_position = slot.ghost_position:unbox()

										drawer:line(ghost_position + z, slot_absolute_position + z, color)
										drawer:sphere(ghost_position + z, 0.3, color)
										drawer:line(ghost_position + z, ai_unit_position + z, color)
									else
										drawer:line(slot_absolute_position + z, ai_unit_position + z, color)
									end
								end

								local text_size = 0.4
								local color_table = (slot.disabled and Colors.get_table("gray"))
									or Colors.get_table(slot.debug_color_name)
								local color_vector = Vector3(color_table[2], color_table[3], color_table[4])
								local category = "slot_index_" .. slot_type .. "_" .. slot.index .. "_" .. i_target

								Managers.state.debug_text:clear_world_text(category)
								Managers.state.debug_text:output_world_text(
									slot.index,
									text_size,
									slot_absolute_position + z,
									nil,
									category,
									color_vector
								)

								local slot_radius = SlotTypeSettings[slot_type].radius

								drawer:circle(slot_absolute_position + z, slot_radius, Vector3.up(), color)
								drawer:circle(slot_absolute_position + z, slot_radius - 0.05, Vector3.up(), color)

								local slot_queue_position = get_slot_queue_position(
									unit_extension_data,
									slot,
									nav_world,
									nil,
									t
								)

								if slot_queue_position then
									drawer:circle(slot_queue_position + z, SLOT_QUEUE_RADIUS, Vector3.up(), color)
									drawer:circle(
										slot_queue_position + z,
										SLOT_QUEUE_RADIUS - 0.05,
										Vector3.up(),
										color
									)
									drawer:line(slot_absolute_position + z, slot_queue_position + z, color)

									local queue = slot.queue
									local queue_n = #queue

									for k = 1, queue_n, 1 do
										local ai_unit_waiting = queue[k]
										local ai_unit_position = POSITION_LOOKUP[ai_unit_waiting]

										drawer:circle(ai_unit_position + z, 0.35, Vector3.up(), color)
										drawer:circle(ai_unit_position + z, 0.3, Vector3.up(), color)
										drawer:line(slot_queue_position + z, ai_unit_position, color)
									end
								end

								local text_size = 0.2 -- luacheck: ignore
								local color_table = (slot.disabled and Colors.get_table("gray"))
									or Colors.get_table(slot.debug_color_name) -- luacheck: ignore
								local color_vector = Vector3(color_table[2], color_table[3], color_table[4]) -- luacheck: ignore
								local category = "wait_slot_index_" .. slot_type .. "_" .. slot.index .. "_" .. i -- luacheck: ignore

								Managers.state.debug_text:clear_world_text(category)

								if slot_queue_position then
									Managers.state.debug_text:output_world_text(
										"wait " .. slot.index,
										text_size,
										slot_queue_position + z,
										nil,
										category,
										color_vector
									)
								end

								if slot.released then
									local color = Colors.get("green") -- luacheck: ignore

									drawer:sphere(slot_absolute_position + z, 0.2, color)
								end

								if is_anchor_slot then
									local color = Colors.get("red") -- luacheck: ignore

									drawer:sphere(slot_absolute_position + z, 0.3, color)
								end

								local check_index = slot.position_check_index
								local check_position = slot_absolute_position

								if check_index == SLOT_POSITION_CHECK_INDEX.CHECK_MIDDLE then -- luacheck: ignore
								else
									local radians = SLOT_POSITION_CHECK_RADIANS[check_index]
									check_position = rotate_position_from_origin(
										check_position,
										target_position,
										radians,
										SLOT_RADIUS
									)
								end

								local ray_from_pos = target_position
									+ Vector3_normalize(check_position - target_position) * RAYCANGO_OFFSET

								drawer:line(ray_from_pos + z, check_position + z, color)
								drawer:circle(check_position + z, 0.1, Vector3.up(), Color(255, 0, 255))
							else
								local category = "wait_slot_index_" .. slot_type .. "_" .. slot.index .. "_" .. i

								Managers.state.debug_text:clear_world_text(category)
							end
						until true
					end
				end
			until true
		end
	end
end

local function debug_print_slots_count(target_units, unit_extension_data)
	local target_slots_n = #target_units
	local target_unit_extensions = unit_extension_data

	Debug.text("OCCUPIED SLOTS")

	for unit_i = 1, target_slots_n, 1 do
		local target_unit = target_units[unit_i]
		local target_unit_extension = target_unit_extensions[target_unit]
		local player_manager = Managers.player
		local owner_player = player_manager:owner(target_unit)
		local display_name = nil -- luacheck: ignore

		if owner_player then
			display_name = owner_player:profile_display_name()
		else
			display_name = tostring(target_unit)
		end

		local debug_text = display_name .. "-> "
		local all_slots = target_unit_extension.all_slots
		local total_slots = 0
		local total_enabled = 0

		for slot_type, slot_data in pairs(all_slots) do
			local disabled_slots_count = slot_data.disabled_slots_count
			local occupied_slots = slot_data.slots_count
			local total_slots_count = slot_data.total_slots_count
			local enabled_slots_count = total_slots_count - disabled_slots_count
			total_slots = total_slots + total_slots_count
			total_enabled = total_enabled + enabled_slots_count
			debug_text = debug_text
				.. string.format("%s: [%d|%d(%d)]. ", slot_type, occupied_slots, enabled_slots_count, total_slots_count)
		end

		local num_occupied_slots = target_unit_extension.num_occupied_slots
		local delayed_occupied_slots = target_unit_extension.delayed_num_occupied_slots
		debug_text = debug_text
			.. string.format(
				"total: [%d(%d)|%d(%d)]. ",
				num_occupied_slots,
				delayed_occupied_slots,
				total_enabled,
				total_slots
			)

		Debug.text(debug_text)
	end
end

return debug_draw_slots
-- return {
--   debug_draw_slots = debug_draw_slots,
--   debug_print_slots_count = debug_print_slots_count
-- }
