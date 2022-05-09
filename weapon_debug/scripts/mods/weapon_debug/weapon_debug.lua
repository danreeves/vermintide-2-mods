-- luacheck: no max line length
-- luacheck: globals get_mod ActionSweep Quaternion Vector3 SweepRangeMod SweepWidthMod SweepHeigthMod script_data Managers QuickDrawerStay Color Matrix4x4 global_is_inside_inn Vector3Box PlayerProjectileImpactUnitExtension ActionUtils Unit PhysicsWorld fassert PlayerProjectileUnitExtension Actor NetworkLookup ScriptUnit AiUtils DamageUtils ActorBox ActionShieldSlam World POSITION_LOOKUP math.degrees_to_radians table.contains BTMeleeOverlapAttackAction PlayerCharacterStateJumping BTStormVerminAttackAction SurroundingAwareSystem DialogueSettings slot22 FrameTable Script BLACKBOARDS ActionFlamethrower Development DebugManager DebugDrawer IngameHud LineObject GwNavTraversal Gui ActionCareerESQuestingKnightActionCareerESQuestingKnight DamageBlobExtension BTWarpfireThrowerShootAction
local mod = get_mod("weapon_debug")

Development._hardcoded_dev_params.disable_debug_draw = false
script_data.disable_debug_draw = false

mod.prev_start_pos = nil
mod.prev_end_pos = nil

local box_color = Color(255, 255, 255)
local time = 0
-- local jump_height = 0
-- local jump_start_height = 0
-- local max_jump_height = 0
-- local jump_height_calibrated = false

-- mod:hook_safe(PlayerCharacterStateJumping, "on_enter", function(_, unit)
--   if not jump_height_calibrated then
--     jump_start_height = Unit.local_position(unit, 0).z
--   end
-- end)
--
-- mod:hook_safe(PlayerCharacterStateJumping, "update", function(_, unit)
--   if not jump_height_calibrated then
--     jump_height = Unit.local_position(unit, 0).z - jump_start_height
--
--     if jump_height ~= 0 then
--       max_jump_height = math.max(jump_height, max_jump_height)
--     end
--   end
-- end)
--
-- mod:hook_safe(PlayerCharacterStateJumping, "on_exit", function()
--   if not jump_height_calibrated then
--     mod:echo("Jump calibrated: jump height %.3f units", max_jump_height)
--     jump_height_calibrated = true
--   end
-- end)

DebugManager.drawer = function(self, options)
  options = options or {}
  local drawer_name = options.name
  local drawer
  local drawer_api = DebugDrawer -- MODIFIED. We just want debug drawer

  if drawer_name == nil then
    local line_object = World.create_line_object(self._world)
    drawer = drawer_api:new(line_object, options.mode)
    self._drawers[#self._drawers + 1] = drawer
  elseif self._drawers[drawer_name] == nil then
    local line_object = World.create_line_object(self._world)
    drawer = drawer_api:new(line_object, options.mode)
    self._drawers[drawer_name] = drawer
  else
    drawer = self._drawers[drawer_name]
  end

  return drawer
end

mod:hook_safe(IngameHud, "update", function(self)
  if not self._currently_visible_components.EquipmentUI then
    local enabled = false
    Development._hardcoded_dev_params.disable_debug_draw = not enabled
    script_data.disable_debug_draw = not enabled
  else
    local enabled = true
    Development._hardcoded_dev_params.disable_debug_draw = not enabled
    script_data.disable_debug_draw = not enabled
  end

end)

mod._world = nil
mod._nav_world = nil
mod._world_gui = nil
mod._line_object = nil
local color_table = {}
for i = 1, 25, 1 do
    color_table[i] = math.random(1, 15)
end

function mod.draw_nav_mesh()

  if not mod:get("show_navmesh") then
    return
  end

  local player = Managers.player:local_player_safe()
  if not player or not player.player_unit then
    return
  end

  local player_unit = player.player_unit
  local position = Unit.world_position(player_unit, 0)
  local offset = Vector3(0, 0, 0.2)

  if not mod._line_object then
    mod.on_setting_changed()
  end

  LineObject.reset(mod._line_object)

  local nav_world = mod._nav_world
  local triangle = GwNavTraversal.get_seed_triangle(mod._nav_world, position)

  if triangle == nil then
    return
  end

  local triangles = {
    triangle
  }
  local num_triangles = 1
  local i = 0

  while num_triangles > i do
    i = i + 1
    triangle = triangles[i]
    local p1, p2, p3 = GwNavTraversal.get_triangle_vertices(nav_world, triangle)
    local triangle_center = p1 + p2 + p3
    local table_index = math.ceil((triangle_center.x + triangle_center.y) % 24 + 1)
    local green = color_table[table_index] * 10

    Gui.triangle(mod._world_gui, p1 + offset, p2 + offset, p3 + offset, 0, Color(150, 0, green, 255))

    local neighbors = {
      GwNavTraversal.get_neighboring_triangles(triangle)
    }

    for j = 1, #neighbors, 1 do
      local neighbor = neighbors[j]
      local is_in_list_already = false

      for k = 1, num_triangles, 1 do
        local triangle2 = triangles[k]

        if GwNavTraversal.are_triangles_equal(neighbor, triangle2) then
          is_in_list_already = true

          break
        end
      end

      if not is_in_list_already then
        local p2_1, p2_2, p2_3 = GwNavTraversal.get_triangle_vertices(nav_world, triangle)

        if Vector3.distance((p2_1 + p2_2 + p2_3) * 0.33, position) < tonumber(mod:get("nav_mesh_distance")) then
          num_triangles = num_triangles + 1
          triangles[num_triangles] = neighbor
        end
      end
    end
  end

  LineObject.dispatch(mod._world, mod._line_object)
end

function mod.on_game_state_changed (status, state)
  if status == "enter" and state == "StateIngame" then
    mod._world = Managers.world:world("level_world")
    mod._nav_world = Managers.state.entity:system("ai_system"):nav_world()
    mod._world_gui = World.create_world_gui(mod._world, Matrix4x4.identity(), 1, 1, "immediate", "material", "materials/fonts/gw_fonts")
    mod._line_object = World.create_line_object(mod._world, false)
  end
end

function mod.update ()
  if Managers.state.debug then
    for _, drawer in pairs(Managers.state.debug._drawers) do
      drawer:update(Managers.state.debug._world)
    end
  end
  mod.draw_nav_mesh()
end

function mod.clear_lines()
  QuickDrawerStay:reset()
end

function mod.on_setting_changed()
  QuickDrawerStay:reset()
  mod._world = Managers.world:world("level_world")
  mod._nav_world = Managers.state.entity:system("ai_system"):nav_world()
  mod._world_gui = World.create_world_gui(mod._world, Matrix4x4.identity(), 1, 1, "immediate", "material", "materials/fonts/gw_fonts")
  mod._line_object = World.create_line_object(mod._world, false)
end

function mod.timescale_up()
  if not Managers.state.debug then
    return
  end
  local timescale_index = Managers.state.debug.time_scale_index
  local timescales = Managers.state.debug.time_scale_list
  if timescale_index == #timescales then
    return
  else
    timescale_index = timescale_index + 1
    Managers.state.debug:set_time_scale(timescale_index)
    if timescales[timescale_index] >= 1 then
      mod:echo("Timescale: %d%%", timescales[timescale_index])
    else
      mod:echo("Timescale: %f%%", timescales[timescale_index])
    end
  end
end

function mod.timescale_down()
  if not Managers.state.debug then
    return
  end
  local timescale_index = Managers.state.debug.time_scale_index
  local timescales = Managers.state.debug.time_scale_list
  if timescale_index == 1 then
    return
  else
    timescale_index = timescale_index - 1
    Managers.state.debug:set_time_scale(timescale_index)
    if timescales[timescale_index] >= 1 then
      mod:echo("Timescale: %d%%", timescales[timescale_index])
    else
      mod:echo("Timescale: %f%%", timescales[timescale_index])
    end
  end
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
local unit_flow_event = Unit.flow_event
local unit_set_flow_variable = Unit.set_flow_variable
local actor_node = Actor.node
local action_hitbox_vertical_fov = math.degrees_to_radians(120)
local action_hitbox_horizontal_fov = math.degrees_to_radians(115.55)
local SWEEP_RESULTS = {}
local function do_overlap (self, dt, t, unit, owner_unit, current_action, physics_world, is_within_damage_window, current_position, current_rotation)
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

  -- Line 2
  do
    if mod:get("show_attack_boxes") then
      local red = Color(255, 0, 0)
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
          local hit_zone_name

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
mod:hook_origin(ActionSweep, "_do_overlap", do_overlap)
mod:hook_origin(ActionCareerESQuestingKnight, "_do_overlap", do_overlap)

mod:hook_safe(ActionSweep, "_send_attack_hit", function (_, _, _, _, _, _, hit_position)
  if mod:get("show_attack_boxes") then
    QuickDrawerStay:sphere(hit_position, 0.015, Color(255, 0, 0))
  end
end)

mod:hook_safe(ActionSweep, "hit_level_object", function(_, _, _, _, _, hit_position)
  if mod:get("show_attack_boxes") then
    QuickDrawerStay:sphere(hit_position, 0.015, Color(255, 0, 0))
  end
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

  if mod:get("show_attack_boxes") then
    QuickDrawerStay:capsule(cached_position, moved_position, radius, Color(255, 255, 255))
  end

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
          self:impact(hit_unit, hit_position, direction, hit_normal, actor_index)
        end
      end
    end
  end
end)

mod:hook_safe(PlayerProjectileImpactUnitExtension, "update_raycast", function (self, unit, input, dt, context, t, override_collision_filter)
  if mod:get("show_attack_boxes") then
    local locomotion_extension = self.locomotion_extension

    if not locomotion_extension:moved_this_frame() then
      return
    end

    local cached_position = locomotion_extension:last_position()
    local moved_position = locomotion_extension:current_position()
    QuickDrawerStay:line(cached_position, moved_position, Color(255, 0, 0))
  end

end)

local function sphere_on_hit_position(_, _, _, hit_position)
  if mod:get("show_attack_boxes") then
    QuickDrawerStay:sphere(hit_position, 0.015, Color(255, 0, 0))
  end
end
mod:hook_safe(PlayerProjectileUnitExtension, "hit_enemy", sphere_on_hit_position)
mod:hook_safe(PlayerProjectileUnitExtension, "hit_player", sphere_on_hit_position)
mod:hook_safe(PlayerProjectileUnitExtension, "hit_level_unit", sphere_on_hit_position)
mod:hook_safe(PlayerProjectileUnitExtension, "hit_non_level_unit", sphere_on_hit_position)

mod:hook_origin(ActionShieldSlam, "_hit", function (self, world, _, owner_unit, current_action)
  if mod:get("only_show_latest_attack") then
    QuickDrawerStay:reset()
  end
  local network_manager = Managers.state.network
  local physics_world = World.get_data(world, "physics_world")
  local attacker_unit_id = network_manager:unit_game_object_id(owner_unit)
  local first_person_unit = self.first_person_unit
  local unit_forward = Quaternion.forward(Unit.local_rotation(first_person_unit, 0))
  local first_person_extension = ScriptUnit.extension(owner_unit, "first_person_system")
  local self_pos = first_person_extension:current_position()
  local forward_offset = current_action.forward_offset or 1
  local attack_pos = self_pos + unit_forward * forward_offset
  local radius = current_action.push_radius
  local collision_filter = "filter_melee_sweep"
  local actors, actors_n = PhysicsWorld.immediate_overlap(physics_world, "shape", "sphere", "position", attack_pos, "size", radius, "types", "dynamics", "collision_filter", collision_filter, "use_global_table")
  local inner_forward_offset = forward_offset + radius * 0.65
  local inner_attack_pos = self_pos + unit_forward * inner_forward_offset
  local inner_attack_pos_near = self_pos + unit_forward
  local inner_radius = current_action.inner_push_radius or radius * 0.4
  local inner_radius_sq = inner_radius * inner_radius
  local inner_hit_units = self.inner_hit_units
  local hit_units = self.hit_units

  if mod:get("show_attack_boxes") then
    QuickDrawerStay:sphere(attack_pos, radius, Color(255, 0, 0))
    QuickDrawerStay:sphere(inner_attack_pos_near, inner_radius, Color(0, 255, 0))
    QuickDrawerStay:sphere(inner_attack_pos, inner_radius, Color(0, 255, 0))
  end

  local target_breed_unit = self.target_breed_unit
  local target_breed_unit_health_extension = Unit.alive(target_breed_unit) and ScriptUnit.extension(target_breed_unit, "health_system")

  if target_breed_unit_health_extension then
    if not target_breed_unit_health_extension:is_alive() then
      target_breed_unit = nil
    end
  else
    target_breed_unit = nil
  end

  local side = Managers.state.side.side_by_unit[owner_unit]
  local player_and_bot_units = side.PLAYER_AND_BOT_UNITS

  for i = 1, actors_n, 1 do
    repeat
      local hit_actor = actors[i]
      local hit_unit = Actor.unit(hit_actor)
      local breed = unit_get_data(hit_unit, "breed")
      local dummy = not breed and unit_get_data(hit_unit, "is_dummy")
      local hit_self = hit_unit == owner_unit
      local target_is_friendly_player = table.contains(player_and_bot_units, hit_unit)

      if not target_is_friendly_player and (breed or dummy) and not hit_units[hit_unit] then
        hit_units[hit_unit] = true
        self._num_targets_hit = self._num_targets_hit + 1

        if hit_unit == target_breed_unit then
          break
        end

        local node = Actor.node(hit_actor)
        local hit_zone = breed and breed.hit_zones_lookup[node]
        local target_hit_zone_name = (hit_zone and hit_zone.name) or "torso"
        local target_hit_position = Unit.has_node(hit_unit, "j_spine") and Unit.world_position(hit_unit, Unit.node(hit_unit, "j_spine"))
        local target_world_position = POSITION_LOOKUP[hit_unit] or Unit.world_position(hit_unit, 0)
        local hit_position = target_hit_position or target_world_position
        self.target_hit_zones_names[hit_unit] = target_hit_zone_name
        self.target_hit_unit_positions[hit_unit] = hit_position
        local attack_direction = Vector3.normalize(hit_position - self_pos)
        local hit_unit_id = network_manager:unit_game_object_id(hit_unit)
        local hit_zone_id = NetworkLookup.hit_zones[target_hit_zone_name]

        if self:_is_infront_player(self_pos, unit_forward, hit_position) then
          local distance_to_inner_position_sq = math.min(Vector3.distance_squared(target_hit_position, inner_attack_pos), Vector3.distance_squared(target_hit_position, inner_attack_pos_near))

          if distance_to_inner_position_sq <= inner_radius_sq then
            inner_hit_units[hit_unit] = true
          else
            local shield_blocked = AiUtils.attack_is_shield_blocked(hit_unit, owner_unit)
            local damage_source = self.item_name
            local damage_source_id = NetworkLookup.damage_sources[damage_source]
            local weapon_system = self.weapon_system
            local power_level = self.power_level
            local is_server = self.is_server
            local damage_profile = self.damage_profile_aoe
            local target_index = 1
            local is_critical_strike = self._is_critical_strike

            if not dummy then
              ActionSweep._play_character_impact(self, is_server, owner_unit, hit_unit, breed, hit_position, target_hit_zone_name, current_action, damage_profile, target_index, power_level, attack_direction, shield_blocked, self.melee_boost_curve_multiplier, is_critical_strike)
            end

            weapon_system:send_rpc_attack_hit(damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id, hit_position, attack_direction, self.damage_profile_aoe_id, "power_level", power_level, "hit_target_index", target_index, "blocking", shield_blocked, "shield_break_procced", false, "boost_curve_multiplier", self.melee_boost_curve_multiplier, "is_critical_strike", self._is_critical_strike, "can_damage", true, "can_stagger", true, "first_hit", self._num_targets_hit == 1)
          end
        end
      elseif not target_is_friendly_player and not hit_units[hit_unit] and not hit_self and ScriptUnit.has_extension(hit_unit, "health_system") then
        local hit_unit_id, is_level_unit = Managers.state.network:game_object_or_level_id(hit_unit)

        if is_level_unit then
          hit_units[hit_unit] = true
          local no_player_damage = unit_get_data(hit_unit, "no_damage_from_players")

          if not no_player_damage then
            local target_hit_position = Unit.world_position(hit_unit, 0)
            local distance_to_inner_position_sq = math.min(Vector3.distance_squared(target_hit_position, inner_attack_pos), Vector3.distance_squared(target_hit_position, inner_attack_pos_near))

            if distance_to_inner_position_sq <= inner_radius_sq then
              inner_hit_units[hit_unit] = true
            else
              local hit_zone_name = "full"
              local target_index = 1
              local damage_profile = self.damage_profile_aoe
              local damage_source = self.item_name
              local power_level = self.power_level
              local is_critical_strike = self._is_critical_strike
              local attack_direction = Vector3.normalize(target_hit_position - self_pos)

              DamageUtils.damage_level_unit(hit_unit, owner_unit, hit_zone_name, power_level, self.melee_boost_curve_multiplier, is_critical_strike, damage_profile, target_index, attack_direction, damage_source)
            end
          end
        else
          hit_units[hit_unit] = true
          local hit_position = POSITION_LOOKUP[hit_unit] or Unit.world_position(hit_unit, 0)
          local distance_to_inner_position_sq = math.min(Vector3.distance_squared(hit_position, inner_attack_pos), Vector3.distance_squared(hit_position, inner_attack_pos_near))

          if distance_to_inner_position_sq <= inner_radius_sq then
            inner_hit_units[hit_unit] = true
          end

          local damage_source = self.item_name
          local damage_source_id = NetworkLookup.damage_sources[damage_source]
          local weapon_system = self.weapon_system
          local power_level = self.power_level
          local hit_zone_id = NetworkLookup.hit_zones.full
          local attack_direction = Vector3.normalize(hit_position - self_pos)

          weapon_system:send_rpc_attack_hit(damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id, hit_position, attack_direction, self.damage_profile_aoe_id, "power_level", power_level, "hit_target_index", nil, "boost_curve_multiplier", self.melee_boost_curve_multiplier, "is_critical_strike", self._is_critical_strike, "can_damage", true, "can_stagger", true)
        end
      end
    until true
  end

  if Unit.alive(target_breed_unit) and not self.hit_target_breed_unit then
    inner_hit_units[target_breed_unit] = true
  end

  local hit_index = 1

  for hit_unit, _ in pairs(inner_hit_units) do
    local breed = unit_get_data(hit_unit, "breed")
    local dummy = not breed and unit_get_data(hit_unit, "is_dummy")
    local hit_zone_name = self.target_hit_zones_names[hit_unit] or "torso"
    local target_hit_position = Unit.has_node(hit_unit, "j_spine") and Unit.world_position(hit_unit, Unit.node(hit_unit, "j_spine"))
    local target_world_position = POSITION_LOOKUP[hit_unit] or Unit.world_position(hit_unit, 0)
    local hit_position = target_hit_position or target_world_position
    local attack_direction = Vector3.normalize(hit_position - self_pos)
    local hit_unit_id, is_level_unit = network_manager:game_object_or_level_id(hit_unit)
    local hit_zone_id = NetworkLookup.hit_zones[hit_zone_name]

    if (breed or dummy) and self:_is_infront_player(self_pos, unit_forward, hit_position, current_action.push_dot) then
      local is_server = self.is_server
      local hit_default_target = hit_unit == target_breed_unit
      local damage_profile = (hit_default_target and self.damage_profile_target) or self.damage_profile
      local damage_profile_id = (hit_default_target and self.damage_profile_target_id) or self.damage_profile_id
      local target_index = 1
      local power_level = self.power_level
      local is_critical_strike = self._is_critical_strike
      local shield_blocked = AiUtils.attack_is_shield_blocked(hit_unit, owner_unit)
      local actor = Unit.find_actor(hit_unit, "c_spine") and Unit.actor(hit_unit, "c_spine")
      local actor_position_hit = actor and Actor.center_of_mass(actor)

      if not dummy and actor_position_hit then
        ActionSweep._play_character_impact(self, is_server, owner_unit, hit_unit, breed, actor_position_hit, hit_zone_name, current_action, damage_profile, target_index, power_level, attack_direction, shield_blocked, self.melee_boost_curve_multiplier, is_critical_strike)
      end

      local send_to_server = true
      local charge_value = damage_profile.charge_value or "heavy_attack"
      local buff_type = DamageUtils.get_item_buff_type(self.item_name)

      DamageUtils.buff_on_attack(owner_unit, hit_unit, charge_value, is_critical_strike, hit_zone_name, hit_index, send_to_server, buff_type)

      local damage_source_id = NetworkLookup.damage_sources[self.item_name]
      local weapon_system = self.weapon_system

      weapon_system:send_rpc_attack_hit(damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id, hit_position, attack_direction, damage_profile_id, "power_level", power_level, "hit_target_index", target_index, "blocking", shield_blocked, "shield_break_procced", false, "boost_curve_multiplier", self.melee_boost_curve_multiplier, "is_critical_strike", is_critical_strike, "can_damage", true, "can_stagger", true, "first_hit", self._num_targets_hit == 1)

      if self.is_critical_strike and self.critical_strike_particle_id then
        World.destroy_particles(self.world, self.critical_strike_particle_id)

        self.critical_strike_particle_id = nil
      end

      if not Managers.player:owner(self.owner_unit).bot_player then
        Managers.state.controller_features:add_effect("rumble", {
            rumble_effect = "handgun_fire"
          })
      end

      self.hit_target_breed_unit = true
      hit_index = hit_index + 1
    elseif ScriptUnit.has_extension(hit_unit, "health_system") then
      if is_level_unit then
        local no_player_damage = unit_get_data(hit_unit, "no_damage_from_players")

        if not no_player_damage then
          hit_zone_name = "full"
          local target_index = 1
          local damage_profile = self.damage_profile
          local damage_source = self.item_name
          local power_level = self.power_level
          local is_critical_strike = self._is_critical_strike
          target_hit_position = Unit.world_position(hit_unit, 0)
          attack_direction = Vector3.normalize(target_hit_position - self_pos)

          DamageUtils.damage_level_unit(hit_unit, owner_unit, hit_zone_name, power_level, self.melee_boost_curve_multiplier, is_critical_strike, damage_profile, target_index, attack_direction, damage_source)
        end
      else
        local damage_source = self.item_name
        local damage_source_id = NetworkLookup.damage_sources[damage_source]
        local weapon_system = self.weapon_system
        local power_level = self.power_level
        hit_zone_id = NetworkLookup.hit_zones.full
        target_hit_position = Unit.world_position(hit_unit, 0)
        attack_direction = Vector3.normalize(target_hit_position - self_pos)

        weapon_system:send_rpc_attack_hit(damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id, target_hit_position, attack_direction, self.damage_profile_id, "power_level", power_level, "hit_target_index", nil, "boost_curve_multiplier", self.melee_boost_curve_multiplier, "is_critical_strike", self._is_critical_strike, "can_damage", true, "can_stagger", true)
      end
    end
  end

  self.state = "hit"
end)

mod:hook_origin(BTMeleeOverlapAttackAction, "overlap_checks", function (self, unit, blackboard, physics_world, t, action, attack, oobb_pos, box_rot, box_size, hit_units, overlap_update_radius)
  local filter_name = (attack.hit_only_players and "filter_player_hit_box_check") or "filter_player_and_enemy_hit_box_check"

  PhysicsWorld.prepare_actors_for_overlap(physics_world, oobb_pos, overlap_update_radius)

  if mod:get("show_attack_boxes") and mod:get("show_enemy_attacks") then
    QuickDrawerStay:oobb_overlap(oobb_pos, box_size, box_rot, Color(255,0,0))
  end

  local hit_actors, num_hit_actors = PhysicsWorld.immediate_overlap(physics_world, "position", oobb_pos, "rotation", box_rot, "size", box_size, "shape", "oobb", "types", "dynamics", "collision_filter", filter_name, "use_global_table")
  local self_pos = POSITION_LOOKUP[unit]
  local unit_rotation = Unit.local_rotation(unit, 0)
  local forward_dir = Quaternion.forward(unit_rotation)
  local hit_multiple_targets = attack.hit_multiple_targets
  local num_hit_units = 0

  for i = 1, num_hit_actors, 1 do
    local hit_actor = hit_actors[i]
    local hit_unit = Actor.unit(hit_actor)

    if Unit.alive(hit_unit) and not hit_units[hit_unit] then
      local hit_unit_pos = POSITION_LOOKUP[hit_unit]

      if hit_unit_pos then
        local attack_dir = Vector3.normalize(hit_unit_pos - self_pos)

        if not attack.ignore_targets_behind or Vector3.dot(attack_dir, forward_dir) > 0 then
          if Managers.player:owner(hit_unit) then
            self:hit_player(unit, blackboard, hit_unit, action, attack)

            hit_units[hit_unit] = true
            num_hit_units = num_hit_units + 1

            if not hit_multiple_targets then
              break
            end
          elseif Unit.has_data(hit_unit, "breed") then
            self:hit_ai(unit, hit_unit, action, attack, blackboard, t)

            hit_units[hit_unit] = true
            num_hit_units = num_hit_units + 1

            if not hit_multiple_targets then
              break
            end
          end
        end
      else
        print("BTMeleeOverlapAttackAction: HIT UNIT MISSING POSITION_LOOKUP ENTRY!", hit_unit)
      end
    end
  end

  return num_hit_units
end)

mod:hook_safe(BTMeleeOverlapAttackAction, "_init_attack", function()
  if mod:get("only_show_latest_attack") and mod:get("show_enemy_attacks") then
    QuickDrawerStay:reset()
  end
end)

mod:hook_origin(BTStormVerminAttackAction, "anim_cb_damage", function (self, unit, blackboard)
  local action = blackboard.action
  blackboard.past_damage_in_attack = true
  local world = Unit.world(unit)
  local pw = World.get_data(world, "physics_world")
  local range = action.range
  local height = action.height
  local width = action.width
  local offset_up = action.offset_up
  local offset_forward = action.offset_forward
  local half_range = range * 0.5
  local half_height = height * 0.5
  local hit_size = Vector3(width * 0.5, half_range, half_height)
  local rat_pos = Unit.local_position(unit, 0)
  local rat_rot = Unit.local_rotation(unit, 0)
  local forward = Quaternion.rotate(rat_rot, Vector3.forward()) * (offset_forward + half_range)
  local up = Vector3.up() * (half_height + offset_up)
  local oobb_pos = rat_pos + forward + up
  local hit_actors, _ = PhysicsWorld.immediate_overlap(pw, "position", oobb_pos, "rotation", rat_rot, "size", hit_size, "shape", "oobb", "types", "dynamics", "collision_filter", "filter_player_hit_box_check", "use_global_table")

  if mod:get("show_attack_boxes") and mod:get("show_enemy_attacks") then
    if mod:get("only_show_latest_attack") then
      QuickDrawerStay:reset()
    end

    -- TODO? Can you jump this attack?
    -- local attack_height = oobb_pos.z + hit_size.z - rat_pos.z
    -- mod:echo("%.3f < %.3f = %s", attack_height, max_jump_height, attack_height < max_jump_height)

    local pose = Matrix4x4.from_quaternion_position(rat_rot, oobb_pos)
    QuickDrawerStay:box(pose, hit_size, Color(255, 0, 0))
  end

  local hit_units = FrameTable.alloc_table()

  if blackboard.moving_attack then
    blackboard.navigation_extension:set_enabled(false)
    blackboard.locomotion_extension:set_wanted_velocity(Vector3(0, 0, 0))
  else
    slot22 = Managers.time:time("game")
  end

  for _, actor in ipairs(hit_actors) do
    local target_unit = Actor.unit(actor)
    hit_units[target_unit] = true
  end

  for target_unit, _ in pairs(hit_units) do
    if not Unit.alive(target_unit) then
      return
    end

    local attack_direction = action.attack_directions and action.attack_directions[blackboard.attack_anim]
    local blocked = DamageUtils.check_block(unit, target_unit, action.fatigue_type, attack_direction)

    if action.damage then
      if not blocked then
        AiUtils.damage_target(target_unit, unit, action, action.damage)
      elseif blocked and action.blocked_damage then
        AiUtils.damage_target(target_unit, unit, action, action.blocked_damage)
      end

      if DamageUtils.is_player_unit(target_unit) and blocked and action.fatigue_type == "complete" then
        SurroundingAwareSystem.add_event(target_unit, "breaking_hit", DialogueSettings.grabbed_broadcast_range, "profile_name", ScriptUnit.extension(target_unit, "dialogue_system").context.player_profile)
      end
    end

    if action.catapult then
      BTStormVerminAttackAction.tag_catapult_enemy(unit, blackboard, action, target_unit, blocked)
    end

    if action.push then
      local self_pos = POSITION_LOOKUP[unit]
      local enemy_pos = POSITION_LOOKUP[target_unit]
      local shove_dir = Vector3.normalize(enemy_pos - self_pos)
      local is_player_unit = DamageUtils.is_player_unit(target_unit)
      local push_speed = action.player_push_speed

      if is_player_unit and push_speed then
        local target_status_extension = ScriptUnit.extension(target_unit, "status_system")

        if not target_status_extension.knocked_down then
          local player_locomotion = ScriptUnit.extension(target_unit, "locomotion_system")

          player_locomotion:add_external_velocity(push_speed * shove_dir, action.max_player_push_speed)
        end
      end
    end
  end
end)

mod:hook_safe(BTMeleeSlamAction, "init_attack", function()
  if mod:get("only_show_latest_attack") and mod:get("show_enemy_attacks") then
    QuickDrawerStay:reset()
  end
end)

mod:hook_origin(BTMeleeSlamAction, "anim_cb_damage", function (self, unit, blackboard)
  local world = blackboard.world
  local physics_world = World.get_data(world, "physics_world")
  local action = blackboard.action
  local unit_forward = Quaternion.forward(Unit.local_rotation(unit, 0))
  local self_pos = POSITION_LOOKUP[unit]
  local pos, rotation, size = self:_calculate_collision(action, self_pos, unit_forward)
  local shape = (size.y - size.x > 0 and "capsule") or "sphere"

  PhysicsWorld.prepare_actors_for_overlap(physics_world, pos, math.max(action.radius, action.height))

  QuickDrawerStay:capsule_overlap(pos, size, rotation, Color(255, 0, 0))

  local hit_actors, num_actors = PhysicsWorld.immediate_overlap(physics_world, "shape", shape, "position", pos, "rotation", rotation, "size", size, "types", "both", "collision_filter", "filter_rat_ogre_melee_slam", "use_global_table")
  local t = Managers.time:time("game")
  local hit_units = FrameTable.alloc_table()

  for i = 1, num_actors, 1 do
    local hit_actor = hit_actors[i]
    local hit_unit = Actor.unit(hit_actor)

    if hit_unit ~= unit and not hit_units[hit_unit] then
      local damage = nil
      local target_status_extension = ScriptUnit.has_extension(hit_unit, "status_system")

      if target_status_extension then
        local dodge = nil
        local to_target = Vector3.flat(POSITION_LOOKUP[hit_unit] - pos)

        if target_status_extension.is_dodging and action.dodge_mitigation_radius_squared < Vector3.length_squared(to_target) then
          dodge = true
        end

        if not dodge then
          local attack_direction_name = action.attack_directions and action.attack_directions[blackboard.attack_anim]

          if target_status_extension:is_disabled() then
            damage = action.damage
          elseif DamageUtils.check_ranged_block(unit, hit_unit, Vector3.normalize(to_target), action.shield_blocked_fatigue_type or "shield_blocked_slam") then
            local blocked_velocity = action.player_push_speed_blocked * Vector3.normalize(POSITION_LOOKUP[hit_unit] - self_pos)
            local locomotion_extension = ScriptUnit.extension(hit_unit, "locomotion_system")

            locomotion_extension:add_external_velocity(blocked_velocity)
          elseif DamageUtils.check_block(unit, hit_unit, action.fatigue_type, attack_direction_name) then
            local blocked_velocity = action.player_push_speed_blocked * Vector3.normalize(POSITION_LOOKUP[hit_unit] - self_pos)
            local locomotion_extension = ScriptUnit.extension(hit_unit, "locomotion_system")

            locomotion_extension:add_external_velocity(blocked_velocity)

            damage = action.blocked_damage
          else
            damage = action.damage
          end
        end

        if action.hit_player_func and damage then
          action.hit_player_func(unit, blackboard, hit_unit, damage)
        end
      elseif Unit.has_data(hit_unit, "breed") then
        local offset = Vector3.flat(POSITION_LOOKUP[hit_unit] - self_pos)
        local direction = nil

        if Vector3.length_squared(offset) < 0.0001 then
          direction = unit_forward
        else
          direction = Vector3.normalize(offset)
        end

        AiUtils.stagger_target(unit, hit_unit, action.stagger_distance, action.stagger_impact, direction, t)

        damage = action.damage
      elseif ScriptUnit.has_extension(hit_unit, "ladder_system") then
        local ladder_ext = ScriptUnit.extension(hit_unit, "ladder_system")

        ladder_ext:shake()
      end

      if damage then
        AiUtils.damage_target(hit_unit, unit, action, action.damage)
      end

      hit_units[hit_unit] = true
    end
  end

  blackboard.rotate_towards_target = false
end)

mod:hook_safe(ActionFlamethrower, "client_owner_start_action", function()
  if mod:get("only_show_latest_attack") then
    mod.clear_lines()
  end
end)

local function to2(num)
  return num
  -- return math.round_with_precision(num, 6)
end

mod:hook_origin(ActionFlamethrower, "_select_targets", function (self, world, show_outline)
  local POSITION_TWEAK = -1.5
  local SPRAY_RANGE = math.abs(POSITION_TWEAK) + 10
  local MAX_TARGETS = 50
  local hit_units = {}

  local owner_unit = self.owner_unit
  local first_person_extension = ScriptUnit.extension(owner_unit, "first_person_system")
  local position_offset = Vector3(0, 0, -0.4)
  local player_position = first_person_extension:current_position() + position_offset
  local first_person_unit = self.first_person_unit
  local player_rotation = Unit.world_rotation(first_person_unit, 0)
  local player_direction = Vector3.normalize(Quaternion.forward(player_rotation))
  local ignore_hitting_allies = not Managers.state.difficulty:get_difficulty_settings().friendly_fire_ranged
  local start_point = player_position + player_direction * POSITION_TWEAK
  local broadphase_radius = 6
  local blackboard = BLACKBOARDS[owner_unit]
  local side = blackboard.side
  local ai_units = {}
  local ai_units_n = AiUtils.broadphase_query(player_position + player_direction * broadphase_radius, broadphase_radius, ai_units)
  local physics_world = World.get_data(world, "physics_world")

  PhysicsWorld.prepare_actors_for_overlap(physics_world, start_point, SPRAY_RANGE * SPRAY_RANGE)


  if mod:get("show_attack_boxes") then
    local forward = Vector3.forward()
    local dot_threshold = self.dot_check or 0.99
    local angle = 0.01
    local rotation = Quaternion.axis_angle(Vector3.up(), angle)
    local test_direction = Quaternion.rotate(rotation, forward)
    local test_dot = Vector3.dot(forward, test_direction)
    local iterations = 0
    while (test_dot ~= dot_threshold) and (test_dot > dot_threshold) and (iterations < 100) do
      iterations = iterations + 1
      test_direction = Quaternion.rotate(rotation, test_direction)
      test_dot = Vector3.dot(forward, test_direction)
    end

    local deg = Vector3.flat_angle(forward, test_direction)
    local r = SPRAY_RANGE * math.tan(deg)

    QuickDrawerStay:cone(player_position, player_position + (player_direction * SPRAY_RANGE), r, Color(255, 0, 0), 20, 10)
  end

  if ai_units_n > 0 then
    local targets = self.targets
    local v, q, m = Script.temp_count()

    table.clear(hit_units)

    local num_hit = 0

    for i = 1, ai_units_n, 1 do
      local hit_unit = ai_units[i]
      local hit_position = POSITION_LOOKUP[hit_unit] + Vector3.up()

      if not hit_units[hit_unit] then
        local is_enemy = side.enemy_units_lookup[hit_unit]

        if (is_enemy or not ignore_hitting_allies) and self:_is_infront_player(player_position, player_direction, hit_position) and self:_check_within_cone(start_point, player_direction, hit_unit, is_enemy) then
          targets[#targets + 1] = hit_unit
          hit_units[hit_unit] = true

          if is_enemy and ScriptUnit.extension(hit_unit, "health_system"):is_alive() then
            num_hit = num_hit + 1
          end
        end

        if MAX_TARGETS <= num_hit then
          break
        end
      end
    end

    Script.set_temp_count(v, q, m)
  end
end)

mod:hook_safe(ActionBulletSpray, "client_owner_start_action", function()
  if mod:get("only_show_latest_attack") then
    mod.clear_lines()
  end
end)

local actor_unit = Actor.unit
local vector3_distance_squared = Vector3.distance_squared
local unit_local_position = Unit.local_position
mod:hook_origin(ActionBulletSpray, "_select_targets", function (self, world, show_outline)
  local POSITION_TWEAK = -1
  local SPRAY_RANGE = math.abs(POSITION_TWEAK) + 5
  local SPRAY_RADIUS = 3.5
  local MAX_TARGETS = 10

  local physics_world = World.get_data(world, "physics_world")
  local owner_unit_1p = self.first_person_unit
  local player_position = POSITION_LOOKUP[owner_unit_1p]
  local player_rotation = Unit.world_rotation(owner_unit_1p, 0)
  local player_direction = Vector3.normalize(Quaternion.forward(player_rotation))
  local ignore_hitting_allies = not Managers.state.difficulty:get_difficulty_settings().friendly_fire_ranged
  local current_action = self.current_action

  if current_action.fire_at_gaze_setting and ScriptUnit.has_extension(self.owner_unit, "eyetracking_system") then
    local eyetracking_extension = ScriptUnit.extension(self.owner_unit, "eyetracking_system")

    if eyetracking_extension:get_is_feature_enabled("tobii_fire_at_gaze") then
      player_direction = eyetracking_extension:gaze_forward()
    end
  end

  local start_point = player_position + player_direction * POSITION_TWEAK + player_direction * SPRAY_RADIUS
  local end_point = player_position + player_direction * POSITION_TWEAK + player_direction * (SPRAY_RANGE - SPRAY_RADIUS)

  PhysicsWorld.prepare_actors_for_overlap(physics_world, start_point, SPRAY_RANGE * SPRAY_RANGE)

  local result = PhysicsWorld.linear_sphere_sweep(physics_world, start_point, end_point, SPRAY_RADIUS, 100, "collision_filter", "filter_character_trigger", "report_initial_overlap")

  table.sort(result, function (a, b)
    local a_unit = actor_unit(a.actor)
    local b_unit = actor_unit(b.actor)
    local a_pos = unit_local_position(a_unit, 0)
    local b_pos = unit_local_position(b_unit, 0)
    local a_distance = vector3_distance_squared(player_position, a_pos)
    local b_distance = vector3_distance_squared(player_position, b_pos)

    return a_distance < b_distance
  end)

  if mod:get("show_attack_boxes") then
    local forward = Vector3.forward()
    local flamethrower_range = current_action.spray_range or SPRAY_RANGE
    local dot_threshold = self.CONE_COS_ALPHA
    local angle = 0.01
    local rotation = Quaternion.axis_angle(Vector3.up(), angle)
    local test_direction = Quaternion.rotate(rotation, forward)
    local test_dot = Vector3.dot(forward, test_direction)
    local iterations = 0
    while test_dot ~= dot_threshold and test_dot > dot_threshold and iterations < 100 do
      iterations = iterations + 1
      test_direction = Quaternion.rotate(rotation, test_direction)
      test_dot = Vector3.dot(forward, test_direction)
    end

    local deg = Vector3.flat_angle(forward, test_direction)
    local r = flamethrower_range * math.tan(deg)

    QuickDrawerStay:cone(player_position, end_point + (player_direction * SPRAY_RANGE), r, Color(255, 0, 0), 20, 10)
  end

  if result then
    local side = Managers.state.side.side_by_unit[self.owner_unit]
    local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
    local num_hits = #result
    local targets = self.targets
    local v, q, m = Script.temp_count()
    local hit_units = {}
    local num_hit = 0

    for i = 1, num_hits, 1 do
      local hit = result[i]
      local hit_actor = hit.actor
      local hit_unit = Actor.unit(hit_actor)
      local hit_position = hit.position

      if not hit_units[hit_unit] then
        local breed = Unit.get_data(hit_unit, "breed")
        local dummy = not breed and Unit.get_data(hit_unit, "is_dummy")

        if table.contains(player_and_bot_units, hit_unit) and not ignore_hitting_allies then
          if self:_is_infront_player(player_position, player_direction, hit_position) and self:_check_within_cone(player_position, player_direction, hit_unit, true) then
            targets[#targets + 1] = hit_unit
            hit_units[hit_unit] = true
          end
        elseif (breed or dummy) and self:_is_infront_player(player_position, player_direction, hit_position) and self:_check_within_cone(player_position, player_direction, hit_unit) then
          targets[#targets + 1] = hit_unit
          hit_units[hit_unit] = true

          if ScriptUnit.extension(hit_unit, "health_system"):is_alive() then
            num_hit = num_hit + 1
          end
        end

        if MAX_TARGETS <= num_hit then
          break
        end
      end
    end

    Script.set_temp_count(v, q, m)
  end
end)

mod:hook_safe(DamageBlobExtension, "insert_blob", function(_, position, radius)
  if mod:get("show_attack_boxes") and mod:get("show_enemy_attacks") then
    local pos1 = position
    local pos2 = position - Vector3(0, 0, 1)
    box_color = Color(255, 0, 0)
    QuickDrawerStay:cylinder(pos1, pos2, radius, box_color, 1)
  end
end)

mod:hook_safe(BTWarpfireThrowerShootAction, "_close_range_attack", function (_, _, attack_pattern_data, _, action)
	local node_name = action.muzzle_node
	local warpfire_unit = attack_pattern_data.warpfire_gun_unit
	local muzzle_node = Unit.node(warpfire_unit, node_name)
	local muzzle_pos = Unit.world_position(warpfire_unit, muzzle_node)
	local forward = Vector3.flat(Quaternion.forward(Unit.world_rotation(warpfire_unit, muzzle_node)))
	local forward_normalized = Vector3.normalize(forward)
	local aim_pos = muzzle_pos + forward_normalized * action.close_attack_range
	local radius = action.hit_radius
	muzzle_pos = muzzle_pos - forward_normalized * 0.5
    if mod:get("show_attack_boxes") and mod:get("show_enemy_attacks") then
      box_color = Color(255, 0, 0)
      QuickDrawerStay:capsule(muzzle_pos, aim_pos, radius, box_color)
    end
end)

---------------------------------------------
--
--


-- local callback_context = {
--     has_gotten_callback = false,
--     overlap_units = {}
-- }
--
-- local function callback(actors)
--     callback_context.has_gotten_callback = true
--     local overlap_units = callback_context.overlap_units
--
--     for k, actor in pairs(actors) do
--         callback_context.num_hits = callback_context.num_hits + 1
--
--         if overlap_units[callback_context.num_hits] == nil then
--             overlap_units[callback_context.num_hits] = ActorBox()
--         end
--
--         overlap_units[callback_context.num_hits]:store(actor)
--     end
-- end
--
-- mod:hook_origin(ActionPushStagger, "client_owner_post_update", function (self, dt, t, world, can_damage)
--     local current_action = self.current_action
--     local owner_unit = self.owner_unit
--     local weapon_system = self.weapon_system
--
--     if self.block_end_time and self.block_end_time < t then
--         if not LEVEL_EDITOR_TEST then
--             local go_id = Managers.state.unit_storage:go_id(owner_unit)
--
--             if self.is_server then
--                 Managers.state.network.network_transmit:send_rpc_clients("rpc_set_blocking", go_id, false)
--             else
--                 Managers.state.network.network_transmit:send_rpc_server("rpc_set_blocking", go_id, false)
--             end
--         end
--
--         local status_extension = self._status_extension
--
--         status_extension:set_blocking(false)
--         status_extension:set_has_blocked(false)
--     end
--
--     if not callback_context.has_gotten_callback and can_damage then
--         mod:echo("if")
--         self.waiting_for_callback = true
--         callback_context.num_hits = 0
--         local physics_world = World.get_data(world, "physics_world")
--         local pos = POSITION_LOOKUP[owner_unit]
--         local buff_extension = self.owner_buff_extension
--         local push_range = buff_extension:apply_buffs_to_value(2.5, "push_range")
--         local radius = math.max(current_action.push_radius, push_range)
--         local collision_filter = "filter_melee_push"
--
--         PhysicsWorld.overlap(physics_world, callback, "shape", "sphere", "position", pos, "size", radius, "types", "dynamics", "collision_filter", collision_filter)
--
--         local first_person_unit = self.owner_unit_first_person
--         local player_rotation = Unit.world_rotation(first_person_unit, 0)
--         local player_direction = Vector3.normalize(Quaternion.forward(player_rotation))
--
--         self._player_direction:store(player_direction)
--     elseif self.waiting_for_callback and callback_context.has_gotten_callback then
--         mod:echo("elseif")
--         self.waiting_for_callback = false
--         callback_context.has_gotten_callback = false
--         local network_manager = Managers.state.network
--         local attacker_unit_id = network_manager:unit_game_object_id(owner_unit)
--         local overlap_units = callback_context.overlap_units
--         local hit_units = self.hit_units
--         local push_units = self.push_units
--         local num_hits = callback_context.num_hits
--         local hit_once = false
--         local player_direction = self._player_direction:unbox()
--         local player_direction_flat = Vector3.flat(player_direction)
--         local buff_extension = self.owner_buff_extension
--         local push_half_angle = math.rad(buff_extension:apply_buffs_to_value(current_action.push_angle or 90, "block_angle") * 0.5)
--         local outer_push_half_angle = math.rad(buff_extension:apply_buffs_to_value(current_action.outer_push_angle or 0, "block_angle") * 0.5)
--         local total_hits = 0
--
--         for i = 1, num_hits, 1 do
--             repeat
--                 local hit_actor = overlap_units[i]:unbox()
--
--                 if hit_actor == nil then
--                     break
--                 end
--
--                 local hit_unit = Actor.unit(hit_actor)
--
--                 if hit_units[hit_unit] == nil and AiUtils.unit_alive(hit_unit) then
--                     hit_units[hit_unit] = true
--                     local is_enemy = DamageUtils.is_enemy(owner_unit, hit_unit)
--
--                     if not is_enemy then
--                         break
--                     end
--                 end
--
--                 local breed = Unit.get_data(hit_unit, "breed")
--
--                 if not breed then
--                     return
--                 end
--
--                 local node = Actor.node(hit_actor)
--                 local hit_zone = breed.hit_zones_lookup[node]
--                 local hit_zone_name = hit_zone.name
--                 local attack_direction = Vector3.normalize(POSITION_LOOKUP[hit_unit] - POSITION_LOOKUP[owner_unit])
--                 local attack_direction_flat = Vector3.flat(attack_direction)
--                 local dot = Vector3.dot(attack_direction_flat, player_direction_flat)
--                 local angle_to_target = math.acos(dot)
--                 local inner_push = angle_to_target <= push_half_angle
--                 local outer_push = push_half_angle < angle_to_target and angle_to_target <= outer_push_half_angle
--
--                 if not inner_push and not outer_push then
--                     break
--                 end
--
--                 total_hits = total_hits + 1
--                 push_units[hit_unit] = {
--                   breed = breed,
--                     hit_actor = hit_actor,
--                     hit_zone_name = hit_zone_name,
--                     inner_push = inner_push,
--                     outer_push = outer_push,
--                     node = node,
--                     attack_direction = attack_direction,
--                     target_index = total_hits
--                 }
--             until true
--         end
--
--         if total_hits == 0 then
--             return
--         end
--
--         for hit_unit, info in pairs(push_units) do
--             repeat
--                 if not Unit.alive(hit_unit) then
--                     break
--                 end
--
--                 if info.inner_push and not info.outer_push then
--                     local push_arc_event = "Play_player_push_ark_success"
--                     local first_person_extension = ScriptUnit.extension(owner_unit, "first_person_system")
--
--                     first_person_extension:play_hud_sound_event(push_arc_event, nil, false)
--                 end
--
--                 local hit_unit_id = network_manager:unit_game_object_id(hit_unit)
--                 local hit_zone_id = NetworkLookup.hit_zones[info.hit_zone_name]
--                 local power_level = self.power_level
--                 local damage_profile_id_to_use = (info.inner_push and self.damage_profile_inner_id) or self.damage_profile_outer_id
--                 local damage_profile_to_use = (info.inner_push and self.damage_profile_inner) or self.damage_profile_outer
--                 local target_settings = damage_profile_to_use.default_target
--                 local hit_position = Unit.world_position(hit_unit, info.node)
--                 local hit_effect = current_action.impact_particle_effect or "fx/impact_block_push"
--                 local hit_unit_root_pos = POSITION_LOOKUP[hit_unit] or Unit.world_position(hit_unit, 0)
--                 local attacker_unit_root_pos = POSITION_LOOKUP[owner_unit] or Unit.world_position(owner_unit, 0)
--                 local attack_direction = Vector3.normalize(hit_unit_root_pos - attacker_unit_root_pos)
--
--                 if hit_effect then
--                     EffectHelper.player_melee_hit_particles(world, hit_effect, hit_position, attack_direction, nil, hit_unit)
--                 end
--
--                 local sound_event = current_action.stagger_impact_sound_event or "blunt_hit"
--
--                 if sound_event then
--                     local attack_template = AttackTemplates[target_settings.attack_template]
--                     local sound_type = (attack_template and attack_template.sound_type) or "stun_heavy"
--                     local husk = self.bot_player
--
--                     EffectHelper.play_melee_hit_effects(sound_event, world, hit_position, sound_type, husk, hit_unit)
--
--                     local sound_event_id = NetworkLookup.sound_events[sound_event]
--                     local sound_type_id = NetworkLookup.melee_impact_sound_types[sound_type]
--                     hit_position = Vector3(math.clamp(hit_position.x, -600, 600), math.clamp(hit_position.y, -600, 600), math.clamp(hit_position.z, -600, 600))
--
--                     if self.is_server then
--                         network_manager.network_transmit:send_rpc_clients("rpc_play_melee_hit_effects", sound_event_id, hit_position, sound_type_id, hit_unit_id)
--                     else
--                         network_manager.network_transmit:send_rpc_server("rpc_play_melee_hit_effects", sound_event_id, hit_position, sound_type_id, hit_unit_id)
--                     end
--                 else
--                     Application.warning("[ActionPushStagger] Missing sound event for push action in unit %q.", self.weapon_unit)
--                 end
--
--                 local shield_blocked = AiUtils.attack_is_shield_blocked(hit_unit, owner_unit)
--                 local damage_source = self.item_name
--                 local damage_source_id = NetworkLookup.damage_sources[damage_source]
--                 local is_critical_strike = self._is_critical_strike
--                 local target_index = info.target_index or nil
--
--
--                 mod:echo(info.breed.name)
--                 weapon_system:send_rpc_attack_hit(damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id, hit_position, attack_direction, damage_profile_id_to_use, "power_level", power_level, "hit_target_index", target_index, "blocking", shield_blocked, "shield_break_procced", false, "boost_curve_multiplier", self.melee_boost_curve_multiplier, "is_critical_strike", is_critical_strike, "can_damage", false, "can_stagger", true, "total_hits", total_hits)
--
--                 if Managers.state.controller_features and self.owner.local_player and not self.has_played_rumble_effect then
--                     Managers.state.controller_features:add_effect("rumble", {
--                         rumble_effect = "push_hit"
--                     })
--
--                     self.has_played_rumble_effect = true
--                 end
--
--                 Managers.state.entity:system("play_go_tutorial_system"):register_push(hit_unit)
--                 buff_extension:trigger_procs("on_push", hit_unit, damage_source)
--
--                 local player_manager = Managers.player
--                 local owner_player = player_manager:owner(self.owner_unit)
--
--                 if not LEVEL_EDITOR_TEST and not player_manager.is_server then
--                     local peer_id = owner_player:network_id()
--                     local local_player_id = owner_player:local_player_id()
--                     local event_id = NetworkLookup.proc_events.on_push
--
--                     Managers.state.network.network_transmit:send_rpc_server("rpc_proc_event", peer_id, local_player_id, event_id)
--                 end
--
--                 hit_once = true
--             until true
--         end
--
--         if hit_once and not self.bot_player then
--             Managers.state.controller_features:add_effect("rumble", {
--                 rumble_effect = "hit_character_light"
--             })
--         end
--     end
-- end)
--
-- mod:hook_origin(ActionPushStagger, "finish", function (self, reason)
--     mod:echo("finish")
--     local hud_extension = ScriptUnit.has_extension(self.owner_unit, "hud_system")
--
--     if hud_extension then
--         hud_extension.show_critical_indication = false
--     end
--
--     self.waiting_for_callback = false
--     callback_context.has_gotten_callback = false
--     local ammo_extension = self.ammo_extension
--     local current_action = self.current_action
--     local owner_unit = self.owner_unit
--
--     if reason ~= "new_interupting_action" then
--         local reload_when_out_of_ammo_condition_func = current_action.reload_when_out_of_ammo_condition_func
--         local do_out_of_ammo_reload = (not reload_when_out_of_ammo_condition_func and true) or reload_when_out_of_ammo_condition_func(owner_unit, reason)
--
--         if ammo_extension and current_action.reload_when_out_of_ammo and do_out_of_ammo_reload and ammo_extension:ammo_count() == 0 and ammo_extension:can_reload() then
--             local play_reload_animation = true
--
--             ammo_extension:start_reload(play_reload_animation)
--         end
--     end
--
--     if not LEVEL_EDITOR_TEST then
--         local go_id = Managers.state.unit_storage:go_id(owner_unit)
--
--         if self.is_server then
--             Managers.state.network.network_transmit:send_rpc_clients("rpc_set_blocking", go_id, false)
--         else
--             Managers.state.network.network_transmit:send_rpc_server("rpc_set_blocking", go_id, false)
--         end
--     end
--
--     local status_extension = self._status_extension
--
--     status_extension:set_blocking(false)
--     status_extension:set_has_blocked(false)
-- end)
--
-- mod:echo("loaded")
