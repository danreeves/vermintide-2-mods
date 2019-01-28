local AI_UPDATES_PER_FRAME = 1
local SLOT_QUEUE_RADIUS = 1.75
local SLOT_QUEUE_RADIUS_SQ = SLOT_QUEUE_RADIUS * SLOT_QUEUE_RADIUS
local SLOT_QUEUE_RANDOM_POS_MAX_UP = 1.5
local SLOT_QUEUE_RANDOM_POS_MAX_DOWN = 2
local SLOT_QUEUE_RANDOM_POS_MAX_HORIZONTAL = 3
local SLOT_Z_MAX_DOWN = 7.5
local SLOT_Z_MAX_UP = 4
local TARGET_MOVED = 0.5
local TARGET_SLOTS_UPDATE = 0.25
local TARGET_SLOTS_UPDATE_LONG = 1
local Z_MAX_DIFFERENCE = 1.5
local NAVMESH_DISTANCE_FROM_WALL = 0.5
local MOVER_RADIUS = 0.6
local RAYCANGO_OFFSET = NAVMESH_DISTANCE_FROM_WALL + MOVER_RADIUS
local SLOT_RADIUS = 0.5
local SLOT_POSITION_CHECK_INDEX = {
  CHECK_LEFT = 0,
  CHECK_RIGHT = 2,
  CHECK_MIDDLE = 1
}
local SLOT_POSITION_CHECK_INDEX_SIZE = table.size(SLOT_POSITION_CHECK_INDEX)
local SLOT_POSITION_CHECK_RADIANS = {
  [SLOT_POSITION_CHECK_INDEX.CHECK_LEFT] = math.degrees_to_radians(-90),
  [SLOT_POSITION_CHECK_INDEX.CHECK_RIGHT] = math.degrees_to_radians(90)
}
local SLOT_STATUS_UPDATE_INTERVAL = 0.5
local TOTAL_SLOTS_COUNT_UPDATE_INTERVAL = 1
local DISABLED_SLOTS_COUNT_UPDATE_INTERVAL = 1
local SLOT_SOUND_UPDATE_INTERVAL = 1
local TARGET_STOPPED_MOVING_SPEED_SQ = 0.25
local PENALTY_TERM = 100

local unit_alive = AiUtils.unit_alive
local unit_knocked_down = AiUtils.unit_knocked_down

local function clamp_position_on_navmesh(position, nav_world, above, below)
  below = below or Z_MAX_DIFFERENCE
  above = above or Z_MAX_DIFFERENCE
  local position_on_navmesh = nil
  local is_on_navmesh, altitude = GwNavQueries.triangle_from_position(nav_world, position, above, below)

  if is_on_navmesh then
    position_on_navmesh = Vector3.copy(position)
    position_on_navmesh.z = altitude
  end

  return (is_on_navmesh and position_on_navmesh) or nil
end

local function get_slot_queue_position(unit_extension_data, slot, nav_world, distance_modifier)
  local target_unit = slot.target_unit
  local ai_unit = slot.ai_unit

  if not unit_alive(target_unit) or not ALIVE[ai_unit] then
    return
  end

  local slot_type = slot.type
  local slot_distance = SlotSettings[slot_type].distance
  local target_unit_extension = unit_extension_data[target_unit]
  local target_unit_position = target_unit_extension.position:unbox()
  local ai_unit_position = POSITION_LOOKUP[ai_unit]
  local slot_queue_direction = slot.queue_direction:unbox()
  local slot_queue_distance_modifier = distance_modifier or 0
  local target_to_ai_distance = Vector3.distance(target_unit_position, ai_unit_position)
  local queue_distance = SlotSettings[slot_type].queue_distance
  local slot_queue_distance = target_to_ai_distance + queue_distance + slot_queue_distance_modifier
  local slot_queue_position = target_unit_position + slot_queue_direction * slot_queue_distance
  local slot_queue_position_on_navmesh = clamp_position_on_navmesh(slot_queue_position, nav_world)
  local max_tries = 5
  local i = 1

  while not slot_queue_position_on_navmesh and i <= max_tries do
    slot_queue_distance = math.max(target_to_ai_distance * (1 - i / max_tries), slot_distance) + queue_distance + slot_queue_distance_modifier
    slot_queue_position = target_unit_position + slot_queue_direction * slot_queue_distance
    slot_queue_position_on_navmesh = clamp_position_on_navmesh(slot_queue_position, nav_world)
    i = i + 1
  end

  local penalty_term = 0

  if not slot_queue_position_on_navmesh then
    penalty_term = PENALTY_TERM
    slot_queue_position = target_unit_position + slot_queue_direction * queue_distance
    return slot_queue_position, penalty_term
  else
    return slot_queue_position_on_navmesh, penalty_term
  end
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
      if best_anchor_weight < slot_anchor_weight or (slot_anchor_weight == best_anchor_weight and slot.index < best_slot.index) then
        best_slot = slot
        best_anchor_weight = slot_anchor_weight
      end
    until true
  end

  return best_slot
end

local function rotate_position_from_origin(origin, position, radians, distance)
  local direction_vector = Vector3.normalize(Vector3.flat(position - origin))
  local rotation = Quaternion(-Vector3.up(), radians)
  local vector = Quaternion.rotate(rotation, direction_vector)
  local position_rotated = origin + vector * distance

  return position_rotated
end

local function debug_draw_slots(target_units, unit_extension_data, nav_world, t)
  local drawer = Managers.state.debug:drawer({
      mode = "immediate",
      name = "AISlotSystem_immediate"
    })
  local z = Vector3.up() * 0.1

  for i = 1, #target_units, 1 do
    repeat
      local target_unit = target_units[i]

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

        drawer:circle(target_position + z, -0.5, Vector3.up(), target_color)
        drawer:circle(target_position + z, -0.45, Vector3.up(), target_color)

        if target_unit_extension.next_slot_status_update_at then
          local percent = (t - target_unit_extension.next_slot_status_update_at) / SLOT_STATUS_UPDATE_INTERVAL
          drawer:circle(target_position + z, 0.45 * percent, Vector3.up(), target_color)
        end

        for j = 1, target_slots_n, 1 do
          repeat
            local slot = target_slots[j]
            local anchor_slot = get_anchor_slot(slot_type, target_unit, unit_extension_data)
            local is_anchor_slot = slot == anchor_slot
            local ai_unit = slot.ai_unit
            local ai_unit_extension = nil
            local alpha = (ai_unit and 255) or 150
            local color = (slot.disabled and Colors.get_color_with_alpha("gray", alpha)) or Colors.get_color_with_alpha(slot.debug_color_name, alpha)

            if slot.absolute_position then
              local slot_absolute_position = slot.absolute_position:unbox()

              if ALIVE[ai_unit] then
                local ai_unit_position = POSITION_LOOKUP[ai_unit]
                local ai_unit_extension = unit_extension_data[ai_unit]

                drawer:circle(ai_unit_position + z, 0.35, Vector3.up(), color)
                drawer:circle(ai_unit_position + z, 0.3, Vector3.up(), color)

                local head_node = Unit.node(ai_unit, "c_head")
                local viewport_name = "player_1"
                local color_table = (slot.disabled and Colors.get_table("gray")) or Colors.get_table(slot.debug_color_name)
                local color_vector = Vector3(color_table[2], color_table[3], color_table[4])
                local offset_vector = Vector3(0, 0, -1)
                local text_size = 0.4
                local text = slot.index
                local category = "slot_index"

                Managers.state.debug_text:clear_unit_text(ai_unit, category)
                Managers.state.debug_text:output_unit_text(text, text_size, ai_unit, head_node, offset_vector, nil, category, color_vector, viewport_name)

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
              local color_table = (slot.disabled and Colors.get_table("gray")) or Colors.get_table(slot.debug_color_name)
              local color_vector = Vector3(color_table[2], color_table[3], color_table[4])
              local category = "slot_index_" .. slot_type .. "_" .. slot.index .. "_" .. i

              Managers.state.debug_text:clear_world_text(category)
              Managers.state.debug_text:output_world_text(slot.index, text_size, slot_absolute_position + z, nil, category, color_vector)

              local slot_radius = SlotSettings[slot_type].radius

              drawer:circle(slot_absolute_position + z, slot_radius, Vector3.up(), color)
              drawer:circle(slot_absolute_position + z, slot_radius - 0.05, Vector3.up(), color)

              local slot_queue_position = get_slot_queue_position(unit_extension_data, slot, nav_world)

              if slot_queue_position then
                drawer:circle(slot_queue_position + z, SLOT_QUEUE_RADIUS, Vector3.up(), color)
                drawer:circle(slot_queue_position + z, SLOT_QUEUE_RADIUS - 0.05, Vector3.up(), color)
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

              if slot.released then
                local color = Colors.get("green")
                drawer:sphere(slot_absolute_position + z, 0.2, color)
              end

              if is_anchor_slot then
                local color = Colors.get("red")
                drawer:sphere(slot_absolute_position + z, 0.3, color)
              end

              local check_index = slot.position_check_index
              local check_position = slot_absolute_position

              if check_index == SLOT_POSITION_CHECK_INDEX.CHECK_MIDDLE then
              else
                local radians = SLOT_POSITION_CHECK_RADIANS[check_index]
                check_position = rotate_position_from_origin(check_position, target_position, radians, SLOT_RADIUS)
              end

              local ray_from_pos = target_position + Vector3.normalize(check_position - target_position) * RAYCANGO_OFFSET
              drawer:line(ray_from_pos + z, check_position + z, color)
              drawer:circle(check_position + z, 0.1, Vector3.up(), Color(255, 0, 255))
            end
          until true
        end
      end
    until true
  end
end

return {
  update = debug_draw_slots
}
