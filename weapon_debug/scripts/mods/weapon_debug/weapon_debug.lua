-- luacheck: no max line length
-- luacheck: globals get_mod ActionSweep Quaternion Vector3 SweepRangeMod SweepWidthMod SweepHeigthMod script_data Managers QuickDrawerStay Color Matrix4x4 global_is_inside_inn Vector3Box PlayerProjectileImpactUnitExtension ActionUtils Unit PhysicsWorld
local mod = get_mod("weapon_debug")
mod:dofile("scripts/mods/weapon_debug/game_code/debug_drawer")
script_data.disable_debug_draw = false

mod.prev_start_pos = nil
mod.prev_end_pos = nil

local box_color = Color(255, 255, 255)
local time = 0

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
  box_color = Color(255, 255, 255)
  time = 0
end)

mod:hook_safe(ActionUtils, "spawn_player_projectile", function()
  if mod:get("only_show_latest_attack") then
	QuickDrawerStay:reset()
  end
end)

local function calculate_attack_direction(action, weapon_rotation)
  local quaternion_axis = action.attack_direction or "forward"
  local attack_direction = Quaternion[quaternion_axis](weapon_rotation)

  return (action.invert_attack_direction and -attack_direction) or attack_direction
end



local unit_alive = Unit.alive
local unit_get_data = Unit.get_data
local unit_world_position = Unit.world_position
local unit_world_rotation = Unit.world_rotation
local unit_local_rotation = Unit.local_rotation
local unit_flow_event = Unit.flow_event
local unit_set_flow_variable = Unit.set_flow_variable
local unit_node = Unit.node
local unit_actor = Unit.actor
local unit_animation_event = Unit.animation_event
local unit_has_animation_event = Unit.has_animation_event
local unit_has_animation_state_machine = Unit.has_animation_state_machine
local actor_node = Actor.node
local action_hitbox_vertical_fov = math.degrees_to_radians(120)
local action_hitbox_horizontal_fov = math.degrees_to_radians(115.55)
local SWEEP_RESULTS = {}
mod:hook_origin(ActionSweep, "_do_overlap", function (self, dt, t, unit, owner_unit, current_action, physics_world, is_within_damage_window, current_position, current_rotation)
  if self._attack_aborted then
	return
  end

  time = time + (dt * 10)
  local num = 255 * math.abs(math.cos(time))
  box_color = Color(255, num, num)

  local current_rot_up = Quaternion.up(current_rotation)
  local hit_environment_rumble = false
  local network_manager = self._network_manager
  local weapon_system = self.weapon_system
  local weapon_up_dir = Quaternion.up(current_rotation)
  local weapon_up_offset_mod = current_action.weapon_up_offset_mod or 0
  local weapon_up_offset = weapon_up_dir * weapon_up_offset_mod

  if not is_within_damage_window and not self._could_damage_last_update then
	local actual_last_position_current = current_position
	local last_position_current = Vector3(actual_last_position_current.x, actual_last_position_current.y, actual_last_position_current.z - self._down_offset) + weapon_up_offset

	self._stored_position:store(last_position_current)
	self._stored_rotation:store(current_rotation)

	return
  end

  local final_frame = not is_within_damage_window and self._could_damage_last_update
  self._could_damage_last_update = is_within_damage_window
  local position_previous = self._stored_position:unbox()
  local rotation_previous = self._stored_rotation:unbox()
  local weapon_up_dir_previous = Quaternion.up(rotation_previous)
  local actual_position_current = current_position
  local position_current = Vector3(actual_position_current.x, actual_position_current.y, actual_position_current.z - self._down_offset) + weapon_up_offset
  local rotation_current = current_rotation

  self._stored_position:store(position_current)
  self._stored_rotation:store(rotation_current)

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
  local weapon_rot = current_rotation
  local position_start = position_previous + weapon_up_dir_previous * weapon_half_length
  local position_end = (position_previous + current_rot_up * weapon_half_length * 2) - Quaternion.up(rotation_previous) * weapon_half_length
  local max_num_hits1 = 5
  local max_num_hits2 = 20
  local max_num_hits3 = 5
  local attack_direction = calculate_attack_direction(current_action, weapon_rot)
  local owner_player = Managers.player:owner(owner_unit)
  local weapon_cross_section = Vector3(weapon_half_extents.x, weapon_half_extents.y, 0.0001)
  local difficulty_rank = Managers.state.difficulty:get_difficulty_rank()
  local collision_filter = "filter_melee_sweep"

  if PhysicsWorld.start_reusing_sweep_tables then
	PhysicsWorld.start_reusing_sweep_tables()
  end


  local red = Color(255, 0, 0)

  -- Line 2
  do
	local start_pos = position_start
	local end_pos = position_end
	local extents = weapon_half_extents
	local rotation = rotation_previous
	local pose = Matrix4x4.from_quaternion_position(rotation, start_pos)
	local movement_vector = end_pos - start_pos

	if is_within_damage_window or self._could_damage_last_update then
	  QuickDrawerStay:box_sweep(pose, extents, movement_vector, box_color, box_color)
	else
	  QuickDrawerStay:box_sweep(pose, extents, movement_vector, red, red)
	end
  end

  local sweep_results1 = PhysicsWorld.linear_obb_sweep(physics_world, position_previous, position_previous + weapon_up_dir_previous * weapon_half_length * 2, weapon_cross_section, rotation_previous, max_num_hits1, "collision_filter", collision_filter, "report_initial_overlap")
  local sweep_results2 = PhysicsWorld.linear_obb_sweep(physics_world, position_start, position_end, weapon_half_extents, rotation_previous, max_num_hits2, "collision_filter", collision_filter, "report_initial_overlap")
  local sweep_results3 = PhysicsWorld.linear_obb_sweep(physics_world, position_previous + current_rot_up * weapon_half_length, position_current + current_rot_up * weapon_half_length, weapon_half_extents, rotation_current, max_num_hits3, "collision_filter", collision_filter, "report_initial_overlap")
  local num_results1 = 0
  local num_results2 = 0
  local num_results3 = 0

  if sweep_results1 then
	num_results1 = #sweep_results1

	for i = 1, num_results1, 1 do
	  SWEEP_RESULTS[i] = sweep_results1[i]
	end
  end

  if sweep_results2 then
	for i = 1, #sweep_results2, 1 do
	  local info = sweep_results2[i]
	  local this_actor = info.actor
	  local found = nil

	  for j = 1, num_results1, 1 do
		if SWEEP_RESULTS[j].actor == this_actor then
		  found = true

		  break
		end
	  end

	  if not found then
		num_results2 = num_results2 + 1
		SWEEP_RESULTS[num_results1 + num_results2] = info
	  end
	end
  end

  if sweep_results3 then
	for i = 1, #sweep_results3, 1 do
	  local info = sweep_results3[i]
	  local this_actor = info.actor
	  local found = nil

	  for j = 1, num_results1 + num_results2, 1 do
		if SWEEP_RESULTS[j].actor == this_actor then
		  found = true

		  break
		end
	  end

	  if not found then
		num_results3 = num_results3 + 1
		SWEEP_RESULTS[num_results1 + num_results2 + num_results3] = info
	  end
	end
  end

  for i = num_results1 + num_results2 + num_results3 + 1, #SWEEP_RESULTS, 1 do
	SWEEP_RESULTS[i] = nil
  end

  local first_person_extension = ScriptUnit.extension(owner_unit, "first_person_system")
  local sound_effect_extension = ScriptUnit.has_extension(owner_unit, "sound_effect_system")
  local damage_profile = self._damage_profile
  local hit_units = self._hit_units
  local environment_unit_hit = false
  local weapon_furthest_point = position_current + current_rot_up * weapon_half_length * 2
  local lost_precision_target = nil

  if current_action.use_precision_sweep and self._precision_target_unit then
	local this_frames_precision_target = self:check_precision_target(owner_unit, owner_player, current_action.dedicated_target_range, true, weapon_furthest_point)

	if self._precision_target_unit ~= this_frames_precision_target then
	  lost_precision_target = true
	  self._precision_target_unit = nil
	end
  end

  local number_of_results_this_frame = num_results1 + num_results2 + num_results3

  if final_frame and self._last_potential_hit_result_has_result then
	local num_added = 0
	local index_to_add_potential = 1

	for i = 1, #self._last_potential_hit_result, 1 do
	  if not self._last_potential_hit_result[i].already_hit then
		local saved_result = {}
		local has_potential_actor = self._last_potential_hit_result[i].actor:unbox()

		if has_potential_actor then
		  saved_result.actor = self._last_potential_hit_result[i].actor:unbox()
		  saved_result.position = self._last_potential_hit_result[i].hit_position:unbox()
		  saved_result.normal = self._last_potential_hit_result[i].hit_normal:unbox()

		  table.insert(SWEEP_RESULTS, index_to_add_potential, saved_result)

		  local potential_unit = self._last_potential_hit_result[i].hit_unit
		  hit_units[potential_unit] = nil
		  index_to_add_potential = index_to_add_potential + 1
		  num_added = num_added + 1
		end
	  end
	end

	number_of_results_this_frame = number_of_results_this_frame + num_added
  end

  local side = Managers.state.side.side_by_unit[owner_unit]
  local enemy_units_lookup = side.enemy_units_lookup
  local view_position, view_rotation = first_person_extension:camera_position_rotation()

  for i = 1, number_of_results_this_frame, 1 do
	local has_potential_result = self._last_potential_hit_result_has_result
	local has_hit_precision_target = self._has_hit_precision_target
	local has_hit_precision_target_and_has_last_hit_result = has_potential_result and (has_hit_precision_target or lost_precision_target)
	local result = SWEEP_RESULTS[i]
	local hit_actor = result.actor
	local hit_unit = Actor.unit(hit_actor)
	local hit_position = result.position
	local hit_normal = result.normal

	if has_hit_precision_target_and_has_last_hit_result then
	  local last_potential_result_index = #self._last_potential_hit_result
	  local use_saved_target_instead = false

	  if lost_precision_target then
		use_saved_target_instead = true
		lost_precision_target = false
	  elseif self._last_potential_hit_result[last_potential_result_index].hit_mass_budget then
		use_saved_target_instead = true
	  end

	  if use_saved_target_instead then
		local last_potential_actor = self._last_potential_hit_result[last_potential_result_index].actor:unbox()

		if last_potential_actor then
		  hit_actor = last_potential_actor
		  hit_unit = Actor.unit(hit_actor)
		  hit_position = self._last_potential_hit_result[last_potential_result_index].hit_position:unbox()
		  hit_normal = self._last_potential_hit_result[last_potential_result_index].hit_normal:unbox()
		  local potential_unit = self._last_potential_hit_result[last_potential_result_index].hit_unit
		  hit_units[potential_unit] = nil
		  self._last_potential_hit_result[last_potential_result_index].already_hit = true
		  i = i - 1
		end
	  end

	  self._last_potential_hit_result_has_result = false
	end

	local hit_armor = false

	if unit_alive(hit_unit) and Vector3.is_valid(hit_position) then
	  fassert(Vector3.is_valid(hit_position), "The hit position is not valid! Actor: %s, Unit: %s", hit_actor, hit_unit)
	  assert(hit_unit, "hit_unit is nil.")

	  hit_unit, hit_actor = ActionUtils.redirect_shield_hit(hit_unit, hit_actor)
	  local breed = AiUtils.unit_breed(hit_unit)
	  local is_dodging = false
	  local in_view = first_person_extension:is_within_custom_view(hit_position, view_position, view_rotation, action_hitbox_vertical_fov, action_hitbox_horizontal_fov)
	  local is_character = breed ~= nil
	  local hit_self = hit_unit == owner_unit
	  local is_friendly_fire = not enemy_units_lookup[hit_unit]
	  local shield_blocked = false

	  if breed and breed.can_dodge then
		is_dodging = AiUtils.attack_is_dodged(hit_unit)
	  end

	  if is_character and not is_friendly_fire and not hit_self and in_view and (has_hit_precision_target_and_has_last_hit_result or self._hit_units[hit_unit] == nil) then
		hit_units[hit_unit] = true
		local status_extension = self._status_extension
		shield_blocked = is_dodging or (AiUtils.attack_is_shield_blocked(hit_unit, owner_unit) and not current_action.ignore_armour_hit and not self._ignore_mass_and_armour and not status_extension:is_invisible())
		local target_health_extension = ScriptUnit.extension(hit_unit, "health_system")
		local can_damage = false
		local can_stagger = false
		local hit_unit_id = network_manager:unit_game_object_id(hit_unit)
		local actual_hit_target_index = 1
		local target_settings = nil

		if current_action.use_precision_sweep and self._precision_target_unit ~= nil and not self._has_hit_precision_target and not final_frame then
		  if hit_unit == self._precision_target_unit then
			self._has_hit_precision_target = true
			actual_hit_target_index, shield_blocked, can_damage, can_stagger = self:_calculate_hit_mass(difficulty_rank, target_health_extension, actual_hit_target_index, shield_blocked, current_action, breed, hit_unit_id)
			target_settings = damage_profile.default_target
		  elseif target_health_extension:is_alive() then
			local potential_target_hit_mass = self:_get_target_hit_mass(difficulty_rank, shield_blocked, current_action, breed, hit_unit_id)
			local num_potential_hits = self._number_of_potential_hit_results + 1
			local result_to_save = {}
			self._last_potential_hit_result_has_result = true
			result_to_save.hit_unit = hit_unit
			result_to_save.actor = ActorBox(hit_actor)
			result_to_save.hit_position = Vector3Box(hit_position)
			result_to_save.hit_normal = Vector3Box(hit_normal)
			result_to_save.hit_mass_budget = self._max_targets - (self._amount_of_mass_hit + potential_target_hit_mass) >= 0
			self._last_potential_hit_result[num_potential_hits] = result_to_save
			self._number_of_potential_hit_results = num_potential_hits
		  end
		elseif self._amount_of_mass_hit < self._max_targets or has_hit_precision_target_and_has_last_hit_result then
		  if not is_friendly_fire then
			actual_hit_target_index, shield_blocked, can_damage, can_stagger = self:_calculate_hit_mass(difficulty_rank, target_health_extension, actual_hit_target_index, shield_blocked, current_action, breed, hit_unit_id)
		  end

		  local targets = damage_profile.targets
		  target_settings = (targets and targets[actual_hit_target_index]) or damage_profile.default_target
		end

		if target_settings then
		  local buff_extension = self._owner_buff_extension
		  local damage_profile_id = self._damage_profile_id
		  local hit_zone_name = nil

		  if breed then
			local node = actor_node(hit_actor)
			local hit_zone = breed.hit_zones_lookup[node]
			hit_zone_name = hit_zone.name
			hit_armor = (target_health_extension:is_alive() and (breed.armor_category == 2 or breed.stagger_armor_category == 2)) or breed.armor_category == 3
		  else
			hit_zone_name = "torso"
		  end

		  local abort_attack = self._max_targets <= self._number_of_hit_enemies or (self._max_targets <= self._amount_of_mass_hit and not self._ignore_mass_and_armour) or (hit_armor and not current_action.slide_armour_hit and not current_action.ignore_armour_hit and not self._ignore_mass_and_armour)

		  if shield_blocked then
			abort_attack = self._max_targets <= self._amount_of_mass_hit + 3 or (hit_armor and not current_action.slide_armour_hit and not current_action.ignore_armour_hit and not self._ignore_mass_and_armour)
		  end

		  local armor_type = breed.armor_category

		  self:_play_hit_animations(owner_unit, current_action, abort_attack, hit_zone_name, armor_type, shield_blocked)

		  if sound_effect_extension and AiUtils.unit_alive(hit_unit) then
			sound_effect_extension:add_hit()
		  end

		  local damage_source = self.item_name
		  local damage_source_id = NetworkLookup.damage_sources[damage_source]
		  local attacker_unit_id = network_manager:unit_game_object_id(owner_unit)
		  local hit_zone_id = NetworkLookup.hit_zones[hit_zone_name]
		  local is_server = self.is_server
		  local backstab_multiplier = self:_check_backstab(breed, nil, hit_unit, owner_unit, buff_extension, first_person_extension)

		  if breed and not is_dodging then
			local has_melee_boost, melee_boost_curve_multiplier = self:_get_power_boost()
			local power_level = self._power_level
			local is_critical_strike = self._is_critical_strike or has_melee_boost

			self:_play_character_impact(is_server, owner_unit, hit_unit, breed, hit_position, hit_zone_name, current_action, damage_profile, actual_hit_target_index, power_level, attack_direction, shield_blocked, melee_boost_curve_multiplier, is_critical_strike, backstab_multiplier)
		  end

		  if is_dodging then
			abort_attack = false
		  end

		  if Managers.state.controller_features and self.owner.local_player and not self._has_played_rumble_effect then
			if hit_armor then
			  Managers.state.controller_features:add_effect("rumble", {
				  rumble_effect = "hit_armor"
				})
			else
			  local hit_rumble_effect = current_action.hit_rumble_effect or "hit_character"

			  Managers.state.controller_features:add_effect("rumble", {
				  rumble_effect = hit_rumble_effect
				})
			end

			if abort_attack then
			  self._has_played_rumble_effect = true
			end
		  end

		  local has_melee_boost, melee_boost_curve_multiplier = self:_get_power_boost()
		  local power_level = self._power_level
		  local is_critical_strike = self._is_critical_strike or has_melee_boost
		  local charge_value = damage_profile.charge_value
		  local shield_break_procc = false
		  local buff_result = "no_buff"

		  if shield_blocked then
			if (charge_value == "heavy_attack" and buff_extension:has_buff_perk("shield_break")) or buff_extension:has_buff_type("armor penetration") then
			  shield_break_procc = true
			end
		  else
			local send_to_server = true
			local number_of_hit_enemies = self._number_of_hit_enemies
			local buff_type = DamageUtils.get_item_buff_type(self.item_name)
			buff_result = DamageUtils.buff_on_attack(owner_unit, hit_unit, charge_value, is_critical_strike, hit_zone_name, number_of_hit_enemies, send_to_server, buff_type)
			local attack_template_id = NetworkLookup.attack_templates[target_settings.attack_template]

			weapon_system:rpc_weapon_blood(nil, attacker_unit_id, attack_template_id)

			local blood_position = Vector3(result.position.x, result.position.y, result.position.z + self._down_offset)

			Managers.state.blood:add_enemy_blood(blood_position, hit_unit, target_health_extension)
		  end

		  if buff_result ~= "killing_blow" then
			self:_send_attack_hit(t, damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id, hit_position, attack_direction, damage_profile_id, "power_level", power_level, "hit_target_index", actual_hit_target_index, "blocking", shield_blocked, "shield_break_procced", shield_break_procc, "boost_curve_multiplier", melee_boost_curve_multiplier, "is_critical_strike", is_critical_strike, "can_damage", can_damage, "can_stagger", can_stagger, "backstab_multiplier", backstab_multiplier, "first_hit", self._number_of_hit_enemies == 1)

			if not shield_blocked and not self.is_server then
			  local attack_template_id = NetworkLookup.attack_templates[target_settings.attack_template]

			  network_manager.network_transmit:send_rpc_server("rpc_weapon_blood", attacker_unit_id, attack_template_id)
			end

			unit_flow_event(self.first_person_unit, "sfx_swing_hit")

			if current_action.add_fatigue_on_hit then
			  self:_handle_fatigue(buff_extension, self._status_extension, current_action, false)
			end
		  else
			first_person_extension:play_hud_sound_event("Play_hud_matchmaking_countdown")
		  end

		  if abort_attack then
			break
		  end
		end
	  elseif not is_character and in_view then
		if ScriptUnit.has_extension(hit_unit, "ai_inventory_item_system") then
		  if not self._hit_units[hit_unit] then
			unit_flow_event(hit_unit, "break_shield")

			self._hit_units[hit_unit] = true
		  end

		  if Managers.state.controller_features and self.owner.local_player and not self._has_played_rumble_effect then
			Managers.state.controller_features:add_effect("rumble", {
				rumble_effect = "hit_shield"
			  })

			self._has_played_rumble_effect = true
		  end
		elseif hit_units[hit_unit] == nil and ScriptUnit.has_extension(hit_unit, "health_system") then
		  local level_index, is_level_unit = Managers.state.network:game_object_or_level_id(hit_unit)
		  local is_dummy_unit = unit_get_data(hit_unit, "is_dummy")

		  if is_dummy_unit then
			local target_health_extension = ScriptUnit.extension(hit_unit, "health_system")
			local hit_unit_armor = unit_get_data(hit_unit, "armor") or 1

			self:_calculate_hit_mass_level_object(hit_unit, target_health_extension, 1, current_action)
			self:hit_level_object(hit_units, hit_unit, owner_unit, current_action, hit_position, attack_direction, level_index, true, hit_actor)
			self:_play_environmental_effect(current_rotation, current_action, hit_unit, hit_position, hit_normal, hit_actor)

			hit_environment_rumble = true
			local is_armored = hit_unit_armor and hit_unit_armor == 2
			local abort_attack = self._max_targets <= self._number_of_hit_enemies or ((is_armored or self._max_targets <= self._amount_of_mass_hit) and not current_action.slide_armour_hit and not self._ignore_mass_and_armour)

			self:_play_hit_animations(owner_unit, current_action, abort_attack)

			if abort_attack then
			  break
			end
		  elseif is_level_unit then
			self:hit_level_object(hit_units, hit_unit, owner_unit, current_action, hit_position, attack_direction, level_index, false)
			self:_play_environmental_effect(current_rotation, current_action, hit_unit, hit_position, hit_normal, hit_actor)

			hit_environment_rumble = true
		  else
			self._hit_units[hit_unit] = hit_unit
			local actual_hit_target_index = math.ceil(self._amount_of_mass_hit + 1)
			local damage_source = self.item_name
			local damage_source_id = NetworkLookup.damage_sources[damage_source]
			local attacker_unit_id = network_manager:unit_game_object_id(owner_unit)
			local hit_unit_id = network_manager:unit_game_object_id(hit_unit)
			local hit_zone_id = NetworkLookup.hit_zones.full
			local damage_profile_id = self._damage_profile_id
			local has_melee_boost, melee_boost_curve_multiplier = self:_get_power_boost()
			local power_level = self._power_level
			local is_critical_strike = self._is_critical_strike or has_melee_boost
			local attack_allowed = unit_get_data(hit_unit, "allow_melee_damage")

			if attack_allowed ~= false then
			  self:_send_attack_hit(t, damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id, hit_position, attack_direction, damage_profile_id, "power_level", power_level, "hit_target_index", actual_hit_target_index, "blocking", shield_blocked, "boost_curve_multiplier", melee_boost_curve_multiplier, "is_critical_strike", is_critical_strike)

			  local abort_attack = not unit_get_data(hit_unit, "weapon_hit_through")

			  self:_play_hit_animations(owner_unit, current_action, abort_attack)
			  self:_play_environmental_effect(current_rotation, current_action, hit_unit, hit_position, hit_normal, hit_actor)

			  hit_environment_rumble = true
			end
		  end
		elseif hit_units[hit_unit] == nil then
		  if global_is_inside_inn then
			local abort_attack = true

			self:_play_hit_animations(owner_unit, current_action, abort_attack)
		  end

		  environment_unit_hit = i
		  hit_environment_rumble = true
		end
	  end

	  if shield_blocked then
		self._amount_of_mass_hit = self._amount_of_mass_hit + 3
	  end
	end
  end

  if environment_unit_hit and not self._has_hit_environment and num_results1 + num_results2 > 0 then
	self._has_hit_environment = true
	local result = SWEEP_RESULTS[environment_unit_hit]
	local hit_actor = result.actor
	local hit_unit = Actor.unit(hit_actor)

	assert(hit_unit, "hit unit is nil")
	fassert(hit_unit, "hit unit is nil")

	if unit ~= hit_unit then
	  local hit_position = result.position
	  local hit_normal = result.normal
	  local hit_direction = attack_direction

	  self:_play_environmental_effect(current_rotation, current_action, hit_unit, hit_position, hit_normal, hit_actor)

	  if Managers.state.controller_features and global_is_inside_inn and self.owner.local_player and not self._has_played_rumble_effect then
		Managers.state.controller_features:add_effect("rumble", {
			rumble_effect = "hit_environment"
		  })

		self._has_played_rumble_effect = true
	  end

	  if hit_unit and unit_alive(hit_unit) and hit_actor then
		unit_set_flow_variable(hit_unit, "hit_actor", hit_actor)
		unit_set_flow_variable(hit_unit, "hit_direction", hit_direction)
		unit_set_flow_variable(hit_unit, "hit_position", hit_position)
		unit_flow_event(hit_unit, "lua_simple_damage")
	  end
	end
  end

  if final_frame then
	self._attack_aborted = true
  end

  if Managers.state.controller_features and global_is_inside_inn and hit_environment_rumble and self.owner.local_player and not self._has_played_rumble_effect then
	Managers.state.controller_features:add_effect("rumble", {
		rumble_effect = "hit_environment"
	  })

	self._has_played_rumble_effect = true
  end

  if PhysicsWorld.stop_reusing_sweep_tables then
	PhysicsWorld.stop_reusing_sweep_tables()
  end
end
)


mod:hook_safe(ActionSweep, "_send_attack_hit", function (_, _, _, _, _, _, hit_position)
  QuickDrawerStay:sphere(hit_position, 0.015, Color(255, 0, 0))
end)

mod:hook_safe(ActionSweep, "hit_level_object", function(_, _, _, _, _, hit_position)
  QuickDrawerStay:sphere(hit_position, 0.015, Color(255, 0, 0))
end)

mod:hook_origin(PlayerProjectileImpactUnitExtension, "update_sphere_sweep", function (self, unit, input, dt, context, t, radius, collision_filter)
  local locomotion_extension = self.locomotion_extension

  if not locomotion_extension:moved_this_frame() then
	return
  end

  local offset = Vector3(0, 0, self.scene_query_height_offset)
  local cached_position = locomotion_extension:last_position() + offset
  local moved_position = locomotion_extension:current_position() + offset
  local physics_world = self.physics_world

  QuickDrawerStay:capsule(cached_position, moved_position, radius, Color(255, 255, 255))

  PhysicsWorld.prepare_actors_for_raycast(physics_world, cached_position, Vector3.normalize(moved_position - cached_position), 0, 1, Vector3.length_squared(moved_position - cached_position))

  local result = PhysicsWorld.linear_sphere_sweep(physics_world, cached_position, moved_position, radius, 100, "collision_filter", collision_filter, "report_initial_overlap")

  if result then
	local direction = Vector3.normalize(moved_position - cached_position)
	local num_hits = #result

	for i = 1, num_hits, 1 do
	  local hit = result[i]
	  local hit_position = hit.position
	  local hit_normal = hit.normal
	  local hit_actor = hit.actor
	  local hit_unit = Actor.unit(hit_actor)

	  if not Unit.is_frozen(hit_unit) then
		local hit_self = hit_unit == unit

		if not hit_self then
		  local num_actors = Unit.num_actors(hit_unit)
		  local actor_index = nil

		  for j = 0, num_actors - 1, 1 do
			local actor = Unit.actor(hit_unit, j)

			if hit_actor == actor then
			  actor_index = j

			  break
			end
		  end

		  fassert(actor_index, "No actor index found for unit [\"%s\"] that was hit on actor [\"%s\"]", hit_unit, hit_actor)

		  QuickDrawerStay:sphere(hit_position, 0.015, Color(255, 0, 0))
		  self:impact(hit_unit, hit_position, direction, hit_normal, actor_index)
		end
	  end
	end
  end
end)

mod:hook_safe(PlayerProjectileImpactUnitExtension, "update_raycast", function (self, unit, input, dt, context, t, override_collision_filter)
  local locomotion_extension = self.locomotion_extension

  if not locomotion_extension:moved_this_frame() then
	return
  end

  local cached_position = locomotion_extension:last_position()
  local moved_position = locomotion_extension:current_position()
  QuickDrawerStay:line(cached_position, moved_position, Color(255, 0, 0))

end)
