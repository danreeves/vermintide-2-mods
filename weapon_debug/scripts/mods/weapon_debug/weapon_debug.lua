-- luacheck: no max line length
-- luacheck: globals get_mod ActionSweep Quaternion Vector3 SweepRangeMod SweepWidthMod SweepHeigthMod script_data Managers QuickDrawerStay Color Matrix4x4 global_is_inside_inn Vector3Box
local mod = get_mod("weapon_debug")
mod:dofile("scripts/mods/weapon_debug/game_code/debug_drawer")
script_data.disable_debug_draw = false

mod.prev_start_pos = nil
mod.prev_end_pos = nil

function mod.update ()
  if Managers.state.debug then
	for _, drawer in pairs(Managers.state.debug._drawers) do
	  drawer:update(Managers.state.debug._world)
	end
  end
end

function mod.clear_lines()
  QuickDrawerStay:reset()
end

mod:hook_safe(ActionSweep, "client_owner_start_action", function()
  if mod:get("only_show_latest_attack") then
	QuickDrawerStay:reset()
  end
  mod.prev_start_pos = nil
  mod.prev_end_pos = nil
end)

-- luacheck: ignore dt t unit owner_unit physics_world
mod:hook(ActionSweep, "_do_overlap", function(func, self, dt, t, unit, owner_unit, current_action, physics_world, is_within_damage_window, current_position, current_rotation)
  if self._attack_aborted then
	return
  end

  local show_boxes = mod:get("show_boxes")

  if not is_within_damage_window and not self._could_damage_last_update then
	return
  end

  local position_previous = self._stored_position:unbox()
  local rotation_previous = self._stored_rotation:unbox()
  local weapon_up_dir_previous = Quaternion.up(rotation_previous)

  local weapon_half_extents = self.stored_half_extents:unbox()
  local weapon_half_length = weapon_half_extents.z
  local range_mod = (current_action.range_mod and current_action.range_mod * SweepRangeMod) or SweepRangeMod
  local width_mod = (current_action.width_mod and current_action.width_mod * SweepWidthMod) or 20 * SweepWidthMod
  local height_mod = (current_action.height_mod and current_action.height_mod * SweepHeigthMod) or 4 * SweepHeigthMod
  local range_mod_add = current_action.range_mod_add or 0

  if global_is_inside_inn then
	range_mod = 0.65 * range_mod
	width_mod = width_mod / 4
  end

  weapon_half_length = weapon_half_length * range_mod + range_mod_add / 2
  weapon_half_extents.x = weapon_half_extents.x * width_mod
  weapon_half_extents.y = weapon_half_extents.y * height_mod
  weapon_half_extents.z = weapon_half_length
  local position_start = position_previous + weapon_up_dir_previous * weapon_half_length

  local white = Color(255, 255, 255)

  -- Line 1
  do
	local start_pos = position_previous
	local end_pos = position_previous + weapon_up_dir_previous * weapon_half_length * 2
	QuickDrawerStay:line(start_pos, end_pos, white)
	if mod.prev_start_pos and mod.prev_end_pos then
	  QuickDrawerStay:line(start_pos, mod.prev_start_pos:unbox(), white)
	  QuickDrawerStay:line(end_pos, mod.prev_end_pos:unbox(), white)
	end
	mod.prev_start_pos = Vector3Box(start_pos)
	mod.prev_end_pos = Vector3Box(end_pos)
  end

  if show_boxes then
	-- Line 2
	do
	  local start_pos = position_start
	  local extents = weapon_half_extents
	  local rotation = rotation_previous
	  local pose = Matrix4x4.from_quaternion_position(rotation, start_pos)
	  local movement_vector = Vector3(0, 0, 0)
	  QuickDrawerStay:box_sweep(pose, extents, movement_vector, white, white)
	end
  end

  func(self, dt, t, unit, owner_unit, current_action, physics_world, is_within_damage_window, current_position, current_rotation)
end)
