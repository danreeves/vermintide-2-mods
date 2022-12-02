-- luacheck: globals get_mod Unit Vector3 Actor DamageUtils Managers ScriptUnit
-- luacheck: globals DefaultPowerLevel NetworkLookup DamageProfileTemplates
-- luacheck: globals ActionUtils Quaternion AiUtils StatusUtils AttackTemplates
-- luacheck: globals ProjectileImpactDataIndex NetworkConstants PlayerProjectileUnitExtension
-- luacheck: globals EffectHelper BoostCurves DamageOutput ActionBeam PlayerUnitStatusSettings
-- luacheck: globals World POSITION_LOOKUP PhysicsWorld
local mod = get_mod("MorePlayers2")

-- WOW
-- Some big functions that need very targetted fixes: checking `hit_zone`
-- exists before indexing it. I have no idea _why_ hit_zone doesn't exist
-- sometimes with more players. But it does and this dumb null check stops
-- it from crashing. No one has complained about this being a bug yet so
-- I think it's safe to ignore.

local INDEX_POSITION = 1
local INDEX_NORMAL = 3
local INDEX_ACTOR = 4
local HIT_UNITS = {}
local HIT_DATA = {}
local unit_get_data = Unit.get_data
local unit_alive = Unit.alive
local unit_actor = Unit.actor
local actor_unit = Actor.unit
local actor_node = Actor.node
local unit_set_flow_variable = Unit.set_flow_variable
local unit_flow_event = Unit.flow_event

mod:hook_origin(DamageUtils, "process_projectile_hit",
  function (world, damage_source, owner_unit, is_server, raycast_result, current_action, direction, check_buffs, target, ignore_list, is_critical_strike, power_level, override_damage_profile_name, target_number)
    table.clear(HIT_UNITS)
    table.clear(HIT_DATA)

    local hit_units = HIT_UNITS
    local hit_data = HIT_DATA
    local attack_direction = direction
    local owner_player = owner_unit and Managers.player:owner(owner_unit)
    local damage_source_id = NetworkLookup.damage_sources[damage_source]
    local check_backstab = false
    local difficulty_settings = Managers.state.difficulty:get_difficulty_settings()
    local owner_buff_extension = ScriptUnit.has_extension(owner_unit, "buff_system")
    local amount_of_mass_hit = 0
    local num_penetrations = 0
    local num_additional_penetrations = 0
    local predicted_damage, shield_blocked = nil
    power_level = power_level or DefaultPowerLevel
    local damage_profile_name = override_damage_profile_name or current_action.damage_profile or "default"
    local override_damage_profile = override_damage_profile_name and DamageProfileTemplates[override_damage_profile_name]
    local damage_profile_id = NetworkLookup.damage_profiles[damage_profile_name]
    local damage_profile = override_damage_profile or DamageProfileTemplates[damage_profile_name]
    local difficulty_level = Managers.state.difficulty:get_difficulty()
    local cleave_power_level = ActionUtils.scale_power_levels(power_level, "cleave", owner_unit, difficulty_level)
    local max_targets_attack, max_targets_impact = ActionUtils.get_max_targets(damage_profile, cleave_power_level)

    if owner_buff_extension then
      if not override_damage_profile or not override_damage_profile.no_procs then
        owner_buff_extension:trigger_procs("on_ranged_hit")
      end

      num_additional_penetrations = owner_buff_extension:apply_buffs_to_value(num_additional_penetrations, "ranged_additional_penetrations")
    end

    local _, ranged_boost_curve_multiplier = ActionUtils.get_ranged_boost(owner_unit)
    local max_targets = (max_targets_impact < max_targets_attack and max_targets_attack) or max_targets_impact
    local owner_is_bot = owner_player and owner_player.bot_player
    local is_husk = (owner_is_bot and true) or false
    local hit_effect = current_action.hit_effect
    local critical_hit_effect = current_action.critical_hit_effect
    local num_hits = #raycast_result
    hit_data.hits = num_penetrations
    local friendly_fire_disabled = damage_profile.no_friendly_fire
    local forced_friendly_fire = damage_profile.always_hurt_players
    local difficulty_rank = Managers.state.difficulty:get_difficulty_rank()
    local allow_friendly_fire = forced_friendly_fire or (not friendly_fire_disabled and DamageUtils.allow_friendly_fire_ranged(difficulty_settings, owner_player))
    local side_manager = Managers.state.side
    local player_manager = Managers.player

    for i = 1, num_hits, 1 do
      repeat
        local hit = raycast_result[i]
        local hit_position = hit[INDEX_POSITION]
        local hit_normal = hit[INDEX_NORMAL]
        local hit_actor = hit[INDEX_ACTOR]
        local hit_valid_target = hit_actor ~= nil
        local hit_unit = (hit_valid_target and actor_unit(hit_actor)) or nil

        if not unit_alive(hit_unit) or Unit.is_frozen(hit_unit) then
          hit_valid_target = false
          hit_unit = nil
        else
          hit_unit, hit_actor = ActionUtils.redirect_shield_hit(hit_unit, hit_actor)
        end

        local attack_hit_self = hit_unit == owner_unit

        if attack_hit_self or not hit_valid_target then
          break
        end

        local target_settings = (damage_profile.targets and damage_profile.targets[num_penetrations + 1]) or damage_profile.default_target
        local hit_rotation = Quaternion.look(hit_normal)
        local is_target = hit_unit == target or target == nil
        local breed = AiUtils.unit_breed(hit_unit)
        local hit_zone_name = nil

        if breed then
          local node = actor_node(hit_actor)
          local hit_zone = breed.hit_zones_lookup[node]
          -- MODIFIED. Check for hit_zone before indexing it
          if hit_zone then
            hit_zone_name = hit_zone.name

            if ignore_list and ignore_list[hit_unit] and hit_zone_name ~= "afro" then
              return hit_data
            end
          end
        end

        local is_player = player_manager:is_player_unit(hit_unit)
        local is_character = breed or is_player
        local block_processing = false

        if is_character and owner_player then
          local side = side_manager.side_by_unit[hit_unit]
          local owner_side = side_manager.side_by_unit[owner_unit]

          if side and owner_side and side.side_id == owner_side.side_id then
            block_processing = not allow_friendly_fire
          end
        end

        if not is_character and not hit_units[hit_unit] then
          amount_of_mass_hit = DamageUtils._projectile_hit_object(current_action, owner_unit, owner_player, owner_buff_extension, target_settings, hit_unit, hit_actor, hit_position, hit_rotation, hit_normal, is_husk, breed, is_server, check_buffs, check_backstab, is_critical_strike, difficulty_rank, power_level, ranged_boost_curve_multiplier, damage_profile, damage_source, critical_hit_effect, world, hit_effect, attack_direction, damage_source_id, damage_profile_id, max_targets, num_penetrations, amount_of_mass_hit)

          if hit_data.stop then
            if num_additional_penetrations > 0 then
              num_additional_penetrations = num_additional_penetrations - 1
              hit_data.stop = false
            else
              hit_data.hit_unit = hit_unit
              hit_data.hit_actor = hit_actor
              hit_data.hit_position = hit_position
              hit_data.hit_direction = attack_direction

              return hit_data
            end
          end
        elseif not hit_units[hit_unit] and is_target and not block_processing then
          amount_of_mass_hit, num_penetrations, predicted_damage, shield_blocked = DamageUtils._projectile_hit_character(current_action, owner_unit, owner_player, owner_buff_extension, target_settings, hit_unit, hit_actor, hit_position, hit_rotation, hit_normal, is_husk, breed, is_server, check_buffs, is_critical_strike, difficulty_rank, power_level, ranged_boost_curve_multiplier, damage_profile, damage_source, critical_hit_effect, world, hit_effect, attack_direction, damage_source_id, damage_profile_id, max_targets, num_penetrations, amount_of_mass_hit, target_number)

          if hit_data.stop then
            if num_additional_penetrations > 0 then
              num_additional_penetrations = num_additional_penetrations - 1
              hit_data.stop = false
            else
              hit_data.hit_unit = hit_unit
              hit_data.hit_actor = hit_actor
              hit_data.hit_position = hit_position
              hit_data.hit_direction = attack_direction
              hit_data.predicted_damage = predicted_damage
              hit_data.shield_blocked = shield_blocked
              hit_data.hit_player = is_player

              return hit_data
            end
          end
        end
      until true
    end

    return hit_data
  end
  )

mod:hook_origin(DamageUtils, "_projectile_hit_character", function (current_action, owner_unit, owner_player, owner_buff_extension, target_settings, hit_unit, hit_actor, hit_position, hit_rotation, hit_normal, is_husk, breed, is_server, check_buffs, is_critical_strike, difficulty_rank, power_level, ranged_boost_curve_multiplier, damage_profile, damage_source, critical_hit_effect, world, hit_effect, attack_direction, damage_source_id, damage_profile_id, max_targets, current_num_penetrations, current_amount_of_mass_hit, target_number)
  local hit_units = HIT_UNITS
  local hit_data = HIT_DATA
  local network_manager = Managers.state.network
  local attacker_unit_id, attacker_is_level_unit = network_manager:game_object_or_level_id(owner_unit)
  local hit_unit_id, _ = network_manager:game_object_or_level_id(hit_unit)
  local hit_zone_name = "torso"
  local predicted_damage = 0
  local shield_blocked = false
  local num_penetrations = current_num_penetrations
  local amount_of_mass_hit = current_amount_of_mass_hit

  if breed then
    local node = actor_node(hit_actor)
    local hit_zone = breed.hit_zones_lookup[node]
    -- MODIFIED. Check for hit_zone before indexing it
    if hit_zone then
      hit_zone_name = hit_zone.name

      if hit_zone_name ~= "afro" then
        shield_blocked = AiUtils.attack_is_shield_blocked(hit_unit, owner_unit) and not current_action.ignore_shield_hit

        if shield_blocked then
          hit_data.blocked_by_unit = hit_unit
        end
      end
    end
  end

  if current_action.hit_zone_override and hit_zone_name ~= "afro" then
    hit_zone_name = current_action.hit_zone_override
  end

  local unmodified = true

  if hit_zone_name ~= "head" and AiUtils.unit_alive(hit_unit) and breed and breed.hit_zones and breed.hit_zones.head then
    local owner_buff_extension = ScriptUnit.has_extension(owner_unit, "buff_system")
    local auto_headshot = owner_buff_extension and owner_buff_extension:has_buff_perk("auto_headshot")

    if auto_headshot and hit_zone_name ~= "afro" then
      hit_zone_name = "head"
      unmodified = false

      owner_buff_extension:trigger_procs("on_auto_headshot")
    end
  end

  if breed and hit_zone_name == "head" and owner_player and not shield_blocked then
    local first_person_extension = ScriptUnit.extension(owner_unit, "first_person_system")
    local _, procced = owner_buff_extension:apply_buffs_to_value(0, "coop_stamina")

    if procced and AiUtils.unit_alive(hit_unit) then
      local headshot_coop_stamina_fatigue_type = breed.headshot_coop_stamina_fatigue_type or "headshot_clan_rat"
      local fatigue_type_id = NetworkLookup.fatigue_types[headshot_coop_stamina_fatigue_type]

      if is_server then
        network_manager.network_transmit:send_rpc_clients("rpc_replenish_fatigue_other_players", fatigue_type_id)
      else
        network_manager.network_transmit:send_rpc_server("rpc_replenish_fatigue_other_players", fatigue_type_id)
      end

      StatusUtils.replenish_stamina_local_players(owner_unit, headshot_coop_stamina_fatigue_type)
      first_person_extension:play_hud_sound_event("hud_player_buff_headshot", nil, false)
    end

    if not current_action.no_headshot_sound and AiUtils.unit_alive(hit_unit) then
      first_person_extension:play_hud_sound_event("Play_hud_headshot", nil, false)
    end
  end

  local hit_unit_player = Managers.player:owner(hit_unit)

  if hit_zone_name == "afro" then
    if breed.is_ai then
      local attacker_is_player = Managers.player:owner(owner_unit)

      if attacker_is_player then
        if is_server then
          if ScriptUnit.has_extension(hit_unit, "ai_system") then
            AiUtils.alert_unit_of_enemy(hit_unit, owner_unit)
          end
        else
          network_manager.network_transmit:send_rpc_server("rpc_alert_enemy", hit_unit_id, attacker_unit_id)
        end
      end
    end
  elseif hit_unit_player and hit_actor == unit_actor(hit_unit, "c_afro") then
    local afro_hit_sound = current_action.afro_hit_sound

    if afro_hit_sound and not hit_unit_player.bot_player and Managers.state.network:game() then
      local sound_id = NetworkLookup.sound_events[afro_hit_sound]

      network_manager.network_transmit:send_rpc("rpc_play_first_person_sound", hit_unit_player.peer_id, hit_unit_id, sound_id, hit_position)
    end
  else
    hit_units[hit_unit] = true
    local hit_zone_id = NetworkLookup.hit_zones[hit_zone_name]
    local attack_template_name = target_settings.attack_template
    local attack_template = AttackTemplates[attack_template_name]

    if owner_player and breed and check_buffs and not shield_blocked then
      local send_to_server = true
      local buff_type = DamageUtils.get_item_buff_type(damage_source)
      local buffs_checked = DamageUtils.buff_on_attack(owner_unit, hit_unit, "instant_projectile", is_critical_strike, hit_zone_name, target_number or num_penetrations + 1, send_to_server, buff_type, unmodified)
      hit_data.buffs_checked = hit_data.buffs_checked or buffs_checked
    end

    local target_health_extension = ScriptUnit.extension(hit_unit, "health_system")

    if breed and target_health_extension:is_alive() then
      local action_mass_override = current_action.hit_mass_count

      if action_mass_override and action_mass_override[breed.name] then
        local mass_cost = current_action.hit_mass_count[breed.name]
        amount_of_mass_hit = amount_of_mass_hit + (mass_cost or 1)
      else
        amount_of_mass_hit = amount_of_mass_hit + ((shield_blocked and ((breed.hit_mass_counts_block and breed.hit_mass_counts_block[difficulty_rank]) or breed.hit_mass_count_block)) or (breed.hit_mass_counts and breed.hit_mass_counts[difficulty_rank]) or breed.hit_mass_count or 1)
      end
    end

    local actual_target_index = math.ceil(amount_of_mass_hit)
    local damage_sound = attack_template.sound_type
    predicted_damage = DamageUtils.calculate_damage(DamageOutput, hit_unit, owner_unit, hit_zone_name, power_level, BoostCurves[target_settings.boost_curve_type], ranged_boost_curve_multiplier, is_critical_strike, damage_profile, actual_target_index, nil, damage_source)
    local no_damage = predicted_damage <= 0

    if breed and not breed.is_hero then
      local enemy_type = breed.name

      if is_critical_strike and critical_hit_effect then
        EffectHelper.play_skinned_surface_material_effects(critical_hit_effect, world, hit_unit, hit_position, hit_rotation, hit_normal, is_husk, enemy_type, damage_sound, no_damage, hit_zone_name, shield_blocked)
      else
        EffectHelper.play_skinned_surface_material_effects(hit_effect, world, hit_unit, hit_position, hit_rotation, hit_normal, is_husk, enemy_type, damage_sound, no_damage, hit_zone_name, shield_blocked)
      end

      if Managers.state.network:game() then
        if is_critical_strike and critical_hit_effect then
          EffectHelper.remote_play_skinned_surface_material_effects(critical_hit_effect, world, hit_position, hit_rotation, hit_normal, enemy_type, damage_sound, no_damage, hit_zone_name, is_server)
        else
          EffectHelper.remote_play_skinned_surface_material_effects(hit_effect, world, hit_position, hit_rotation, hit_normal, enemy_type, damage_sound, no_damage, hit_zone_name, is_server)
        end
      end
    elseif hit_unit_player and breed.is_hero and current_action.player_push_velocity then
      local hit_unit_buff_extension = ScriptUnit.has_extension(hit_unit, "buff_system")
      local no_ranged_knockback = hit_unit_buff_extension and hit_unit_buff_extension:has_buff_perk("no_ranged_knockback")

      if not no_ranged_knockback then
        local status_extension = ScriptUnit.extension(hit_unit, "status_system")

        if not status_extension:is_disabled() then
          local max_impact_push_speed = current_action.max_impact_push_speed
          local locomotion = ScriptUnit.extension(hit_unit, "locomotion_system")

          locomotion:add_external_velocity(current_action.player_push_velocity:unbox(), max_impact_push_speed)
        end
      end
    end

    local deal_damage = true
    local owner_unit_alive = unit_alive(owner_unit)

    if owner_unit_alive and hit_unit_player then
      local ranged_block = DamageUtils.check_ranged_block(owner_unit, hit_unit, attack_direction, "blocked_ranged")
      deal_damage = not ranged_block
      shield_blocked = ranged_block
    end

    if deal_damage then
      if owner_buff_extension then
        owner_buff_extension:trigger_procs("on_ranged_hit", hit_unit)
      end

      local weapon_system = Managers.state.entity:system("weapon_system")

      weapon_system:send_rpc_attack_hit(damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id, hit_position, attack_direction, damage_profile_id, "power_level", power_level, "hit_target_index", actual_target_index, "blocking", shield_blocked, "shield_break_procced", false, "boost_curve_multiplier", ranged_boost_curve_multiplier, "is_critical_strike", is_critical_strike, "attacker_is_level_unit", attacker_is_level_unit, "first_hit", num_penetrations == 0)
      EffectHelper.player_critical_hit(world, is_critical_strike, owner_unit, hit_unit, hit_position)

      if not owner_player and owner_unit_alive and hit_unit_player and hit_unit_player.bot_player then
        local bot_ai_extension = ScriptUnit.extension(hit_unit, "ai_system")

        bot_ai_extension:hit_by_projectile(owner_unit)
      end
    end

    local dummy_unit_armor = unit_get_data(hit_unit, "armor")
    local target_unit_armor, _, target_unit_primary_armor, _ = ActionUtils.get_target_armor(hit_zone_name, breed, dummy_unit_armor)

    if no_damage or shield_blocked or target_unit_primary_armor == 6 or target_unit_armor == 2 then
      max_targets = num_penetrations
    else
      num_penetrations = num_penetrations + 1
    end

    if max_targets <= amount_of_mass_hit then
      hit_data.stop = true
      hit_data.hits = num_penetrations
    end
  end

  return amount_of_mass_hit, num_penetrations, predicted_damage, shield_blocked
end)

mod:hook_origin(DamageUtils, "_projectile_hit_object", function (current_action, owner_unit, owner_player, owner_buff_extension, target_settings, hit_unit, hit_actor, hit_position, hit_rotation, hit_normal, is_husk, breed, is_server, check_buffs, check_backstab, is_critical_strike, difficulty_rank, power_level, ranged_boost_curve_multiplier, damage_profile, damage_source, critical_hit_effect, world, hit_effect, attack_direction, damage_source_id, damage_profile_id, max_targets, num_penetrations, current_amount_of_mass_hit)
	local hit_units = HIT_UNITS
	local hit_data = HIT_DATA
	local ai_system = Managers.state.entity:system("ai_system")
	local network_manager = Managers.state.network
	local _, is_level_unit = network_manager:game_object_or_level_id(hit_unit)
	local is_dummy_unit = not is_level_unit and unit_get_data(hit_unit, "is_dummy")
	local has_health_extension = ScriptUnit.has_extension(hit_unit, "health_system")
	local owner = Managers.player:owner(hit_unit)
	local hit_zone_name = "full"
	local amount_of_mass_hit = current_amount_of_mass_hit
	local allow_ranged_damage = unit_get_data(hit_unit, "allow_ranged_damage") ~= false

	if is_dummy_unit and not hit_units[hit_unit] then
		hit_units[hit_unit] = true
		local node = actor_node(hit_actor)
		local head_actor = Unit.actor(hit_unit, "c_head")
		local head_node = actor_node(head_actor)

		if node == head_node then
			if AiUtils.unit_alive(hit_unit) and not current_action.no_headshot_sound then
				local first_person_extension = ScriptUnit.has_extension(owner_unit, "first_person_system")

				if first_person_extension then
					first_person_extension:play_hud_sound_event("Play_hud_headshot", nil, false)
				end
			end

			hit_zone_name = "head"
		end

		amount_of_mass_hit = amount_of_mass_hit + 1
		local target_index = math.ceil(amount_of_mass_hit)

		DamageUtils.damage_dummy_unit(hit_unit, owner_unit, hit_zone_name, power_level, ranged_boost_curve_multiplier, is_critical_strike, damage_profile, target_index, hit_position, attack_direction, damage_source, hit_actor, damage_profile_id, check_buffs, check_backstab)

		hit_data.buffs_checked = true
		hit_data.stop = true
		hit_data.hits = num_penetrations + 1
	elseif is_level_unit and not hit_units[hit_unit] and (GameSettingsDevelopment.allow_ranged_attacks_to_damage_props or allow_ranged_damage) and has_health_extension then
		hit_units[hit_unit] = true
		amount_of_mass_hit = amount_of_mass_hit + 1
		local target_index = math.ceil(amount_of_mass_hit)

		DamageUtils.damage_level_unit(hit_unit, owner_unit, hit_zone_name, power_level, ranged_boost_curve_multiplier, is_critical_strike, damage_profile, target_index, attack_direction, damage_source)

		hit_data.stop = true
		hit_data.hits = num_penetrations + 1
	elseif not is_level_unit and allow_ranged_damage and has_health_extension and not owner then
		hit_units[hit_unit] = true
		local attacker_unit_id = network_manager:unit_game_object_id(owner_unit)
		local hit_unit_id = network_manager:unit_game_object_id(hit_unit)
		local hit_zone_id = NetworkLookup.hit_zones[hit_zone_name]
		local weapon_system = Managers.state.entity:system("weapon_system")

		weapon_system:send_rpc_attack_hit(damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id, hit_position, attack_direction, damage_profile_id, "power_level", power_level, "hit_target_index", nil, "blocking", false, "shield_break_procced", false, "boost_curve_multiplier", ranged_boost_curve_multiplier, "is_critical_strike", is_critical_strike, "first_hit", num_penetrations == 0)

		if is_critical_strike and critical_hit_effect then
			EffectHelper.play_surface_material_effects(critical_hit_effect, world, hit_unit, hit_position, hit_rotation, hit_normal, nil, is_husk, nil, hit_actor)
		else
			EffectHelper.play_surface_material_effects(hit_effect, world, hit_unit, hit_position, hit_rotation, hit_normal, nil, is_husk, nil, hit_actor)
		end

		if Managers.state.network:game() then
			if is_critical_strike and critical_hit_effect then
				EffectHelper.remote_play_surface_material_effects(critical_hit_effect, world, hit_unit, hit_position, hit_rotation, hit_normal, is_server, hit_actor)
			else
				EffectHelper.remote_play_surface_material_effects(hit_effect, world, hit_unit, hit_position, hit_rotation, hit_normal, is_server, hit_actor)
			end
		end

		hit_data.stop = true
		hit_data.hits = num_penetrations + 1
	else
		if current_action.alert_sound_range_hit and owner_unit then
			ai_system:alert_enemies_within_range(owner_unit, hit_position, current_action.alert_sound_range_fire)
		end

		local is_inventory_item = ScriptUnit.has_extension(hit_unit, "ai_inventory_item_system")

		if not is_inventory_item then
			local hit_unit_owner = Managers.player:owner(hit_unit)

			if hit_unit_owner == nil or hit_unit_owner.player_unit == nil then
				if is_critical_strike and critical_hit_effect then
					EffectHelper.play_surface_material_effects(critical_hit_effect, world, hit_unit, hit_position, hit_rotation, hit_normal, nil, is_husk, nil, hit_actor)
				else
					EffectHelper.play_surface_material_effects(hit_effect, world, hit_unit, hit_position, hit_rotation, hit_normal, nil, is_husk, nil, hit_actor)
				end

				if Managers.state.network:game() then
					if is_critical_strike and critical_hit_effect then
						EffectHelper.remote_play_surface_material_effects(critical_hit_effect, world, hit_unit, hit_position, hit_rotation, hit_normal, is_server, hit_actor)
					else
						EffectHelper.remote_play_surface_material_effects(hit_effect, world, hit_unit, hit_position, hit_rotation, hit_normal, is_server, hit_actor)
					end
				end

				if allow_ranged_damage and hit_unit and unit_alive(hit_unit) and hit_actor then
					local hit_direction = Vector3.multiply(hit_normal, -1)

					unit_set_flow_variable(hit_unit, "hit_actor", hit_actor)
					unit_set_flow_variable(hit_unit, "hit_direction", hit_direction)
					unit_set_flow_variable(hit_unit, "hit_position", hit_position)
					unit_flow_event(hit_unit, "lua_simple_damage")
				end
			end

			hit_data.stop = true
			hit_data.hits = 1
		end
	end

	return amount_of_mass_hit
end)

local best_hit_units = {}
mod:hook_origin(PlayerProjectileUnitExtension, "handle_impacts", function (self, impacts, num_impacts, time)
	table.clear(best_hit_units)

	local unit = self._projectile_unit
	local owner_unit = self._owner_unit
	local is_server = self._is_server
	local UNIT_INDEX = ProjectileImpactDataIndex.UNIT
	local POSITION_INDEX = ProjectileImpactDataIndex.POSITION
	local DIRECTION_INDEX = ProjectileImpactDataIndex.DIRECTION
	local NORMAL_INDEX = ProjectileImpactDataIndex.NORMAL
	local ACTOR_INDEX = ProjectileImpactDataIndex.ACTOR_INDEX
	local hit_units = self._hit_units
	local hit_afro_units = self._hit_afro_units
	local impact_data = self._impact_data
	local network_manager = Managers.state.network
	local network_transmit = network_manager.network_transmit
	local unit_id = network_manager:unit_game_object_id(unit)
	local pos_min = NetworkConstants.position.min
	local pos_max = NetworkConstants.position.max

	for i = 1, num_impacts / ProjectileImpactDataIndex.STRIDE, 1 do
		local j = (i - 1) * ProjectileImpactDataIndex.STRIDE
		local hit_position = impacts[j + POSITION_INDEX]:unbox()
		local hit_unit = impacts[j + UNIT_INDEX]
		local actor_index = impacts[j + ACTOR_INDEX]
		local hit_actor = Unit.actor(hit_unit, actor_index)
		local breed = AiUtils.unit_breed(hit_unit)

		if breed then
			local node = Actor.node(hit_actor)
			local hit_zone = breed.hit_zones_lookup[node]

			if hit_zone and hit_zone.name ~= "afro" then
				local potential_hit_zone = best_hit_units[hit_unit]

				if not potential_hit_zone or (potential_hit_zone and hit_zone.prio < potential_hit_zone.prio) then
					best_hit_units[hit_unit] = hit_zone
				end
			elseif not hit_afro_units[hit_unit] and hit_zone and hit_zone.name == "afro" then
				self:_alert_enemy(hit_unit, owner_unit)

				hit_afro_units[hit_unit] = true
			end
		end
	end

	for i = 1, num_impacts / ProjectileImpactDataIndex.STRIDE, 1 do
		repeat
			if self._stop_impacts then
				return
			end

			local j = (i - 1) * ProjectileImpactDataIndex.STRIDE
			local hit_unit = impacts[j + UNIT_INDEX]
			local hit_position = impacts[j + POSITION_INDEX]:unbox()
			local hit_direction = impacts[j + DIRECTION_INDEX]:unbox()
			local hit_normal = impacts[j + NORMAL_INDEX]:unbox()
			local actor_index = impacts[j + ACTOR_INDEX]
			local hit_actor = Unit.actor(hit_unit, actor_index)
			local valid_position = self:validate_position(hit_position, pos_min, pos_max)

			if not valid_position then
				self:stop()
			end

			hit_unit, hit_actor = ActionUtils.redirect_shield_hit(hit_unit, hit_actor)
			local hit_self = hit_unit == owner_unit

			if not hit_self and valid_position and not hit_units[hit_unit] then
				local hud_extension = ScriptUnit.has_extension(owner_unit, "hud_system")

				if hud_extension then
					hud_extension.show_critical_indication = false
				end

				local timed_data = self._timed_data

				if timed_data and timed_data.activate_life_time_on_impact then
					self:_activate_life_time(time)
				end

				local breed = AiUtils.unit_breed(hit_unit)

				if breed then
					local best_hit_zone = best_hit_units[hit_unit]

					if best_hit_zone then
						local node = Actor.node(hit_actor)
						local hit_zone = breed.hit_zones_lookup[node]

                        -- MODIFIED. Check for hitzone before indexing it
						if hit_zone and hit_zone.name == best_hit_zone.name then
							hit_units[hit_unit] = true
						else
							break
						end
					else
						break
					end
				else
					hit_units[hit_unit] = true
				end

				local level_index, is_level_unit = network_manager:game_object_or_level_id(hit_unit)

				if is_server then
					if is_level_unit then
						network_transmit:send_rpc_clients("rpc_player_projectile_impact_level", unit_id, level_index, hit_position, hit_direction, hit_normal, actor_index)
					elseif level_index then
						network_transmit:send_rpc_clients("rpc_player_projectile_impact_dynamic", unit_id, level_index, hit_position, hit_direction, hit_normal, actor_index)
					end
				elseif is_level_unit then
					network_transmit:send_rpc_server("rpc_player_projectile_impact_level", unit_id, level_index, hit_position, hit_direction, hit_normal, actor_index)
				elseif level_index then
					network_transmit:send_rpc_server("rpc_player_projectile_impact_dynamic", unit_id, level_index, hit_position, hit_direction, hit_normal, actor_index)
				end

				local side_manager = Managers.state.side
				local is_enemy = side_manager:is_enemy(owner_unit, hit_unit)
				local has_ranged_boost, ranged_boost_curve_multiplier = ActionUtils.get_ranged_boost(owner_unit)

				if breed then
					if is_enemy then
						self:hit_enemy(impact_data, hit_unit, hit_position, hit_direction, hit_normal, hit_actor, breed, has_ranged_boost, ranged_boost_curve_multiplier)

						local buff_extension = ScriptUnit.has_extension(owner_unit, "buff_system")

						if buff_extension then
							buff_extension:trigger_procs("on_ranged_hit")
						end
					elseif breed.is_player then
						self:hit_player(impact_data, hit_unit, hit_position, hit_direction, hit_normal, hit_actor, has_ranged_boost, ranged_boost_curve_multiplier)
					end
				elseif is_level_unit or Unit.get_data(hit_unit, "is_dummy") then
					self:hit_level_unit(impact_data, hit_unit, hit_position, hit_direction, hit_normal, hit_actor, level_index, has_ranged_boost, ranged_boost_curve_multiplier)
				elseif not is_level_unit then
					self:hit_non_level_unit(impact_data, hit_unit, hit_position, hit_direction, hit_normal, hit_actor, has_ranged_boost, ranged_boost_curve_multiplier)
				end
			end
		until true
	end
end)

mod:hook_origin(ActionBeam, "client_owner_post_update", function (self, dt, t, world, can_damage)
	local owner_unit = self.owner_unit
	local current_action = self.current_action
	local is_server = self.is_server
	local input_extension = ScriptUnit.extension(self.owner_unit, "input_system")
	local buff_extension = self.owner_buff_extension
	local status_extension = self.status_extension

	if not status_extension:is_zooming() then
		status_extension:set_zooming(true)
	end

	if buff_extension:has_buff_type("increased_zoom") and status_extension:is_zooming() and input_extension:get("action_three") then
		status_extension:switch_variable_zoom(current_action.buffed_zoom_thresholds)
	elseif current_action.zoom_thresholds and status_extension:is_zooming() and input_extension:get("action_three") then
		status_extension:switch_variable_zoom(current_action.zoom_thresholds)
	end

	if self.state == "waiting_to_shoot" and self.time_to_shoot <= t then
		self.state = "shooting"
	end

	self.overcharge_timer = self.overcharge_timer + dt

	if current_action.overcharge_interval <= self.overcharge_timer then
		local overcharge_amount = PlayerUnitStatusSettings.overcharge_values.charging

		self.overcharge_extension:add_charge(overcharge_amount)

		self._is_critical_strike = ActionUtils.is_critical_strike(owner_unit, current_action, t)
		self.overcharge_timer = 0
		self.overcharge_target_hit = false
	end

	if self.state == "shooting" then
		if not Managers.player:owner(self.owner_unit).bot_player and not self._rumble_effect_id then
			self._rumble_effect_id = Managers.state.controller_features:add_effect("persistent_rumble", {
				rumble_effect = "reload_start"
			})
		end

		local first_person_extension = ScriptUnit.extension(owner_unit, "first_person_system")
		local current_position, current_rotation = first_person_extension:get_projectile_start_position_rotation()
		local direction = Quaternion.forward(current_rotation)
		local physics_world = World.get_data(self.world, "physics_world")
		local range = current_action.range or 30
		local result = PhysicsWorld.immediate_raycast_actors(physics_world, current_position, direction, range, "static_collision_filter", "filter_player_ray_projectile_static_only", "dynamic_collision_filter", "filter_player_ray_projectile_ai_only", "dynamic_collision_filter", "filter_player_ray_projectile_hitbox_only")
		local beam_end_position = current_position + direction * range
		local hit_unit, hit_position = nil

		if result then
			local difficulty_settings = Managers.state.difficulty:get_difficulty_settings()
			local owner_player = self.owner_player
			local allow_friendly_fire = DamageUtils.allow_friendly_fire_ranged(difficulty_settings, owner_player)

			for _, hit_data in pairs(result) do
				local potential_hit_position = hit_data[INDEX_POSITION]
				local hit_actor = hit_data[INDEX_ACTOR]
				local potential_hit_unit = Actor.unit(hit_actor)
				potential_hit_unit, hit_actor = ActionUtils.redirect_shield_hit(potential_hit_unit, hit_actor)

				if potential_hit_unit ~= owner_unit then
					local breed = Unit.get_data(potential_hit_unit, "breed")
					local hit_enemy = nil

					if breed then
						local is_enemy = DamageUtils.is_enemy(owner_unit, potential_hit_unit)
						local node = Actor.node(hit_actor)
						local hit_zone = breed.hit_zones_lookup[node]
                        -- MODIFIED. Check for hit_zone before indexing it
                        if hit_zone then
                          local hit_zone_name = hit_zone.name
                          hit_enemy = (allow_friendly_fire or is_enemy) and hit_zone_name ~= "afro"
                        end
					else
						hit_enemy = true
					end

					if hit_enemy then
						hit_position = potential_hit_position - direction * 0.15
						hit_unit = potential_hit_unit

						break
					end
				end
			end

			if hit_position then
				beam_end_position = hit_position
			end

			if hit_unit then
				local health_extension = ScriptUnit.has_extension(hit_unit, "health_system")

				if health_extension then
					if hit_unit ~= self.current_target then
						self.ramping_interval = 0.4
						self.damage_timer = 0
						self._num_hits = 0
					end

					if self.damage_timer >= current_action.damage_interval * self.ramping_interval then
						Managers.state.entity:system("ai_system"):alert_enemies_within_range(owner_unit, POSITION_LOOKUP[owner_unit], 5)

						self.damage_timer = 0

						if health_extension then
							self.ramping_interval = math.clamp(self.ramping_interval * 1.4, 0.45, 1.5)
						end
					end

					if self.damage_timer == 0 then
						local is_critical_strike = self._is_critical_strike
						local hud_extension = ScriptUnit.has_extension(owner_unit, "hud_system")

						self:_handle_critical_strike(is_critical_strike, buff_extension, hud_extension, first_person_extension, "on_critical_shot", nil)

						if health_extension then
							local override_damage_profile = nil
							local power_level = self.power_level
							power_level = power_level * self.ramping_interval

							if hit_unit ~= self.current_target then
								self.consecutive_hits = 0
								power_level = power_level * 0.5
								override_damage_profile = current_action.initial_damage_profile or current_action.damage_profile or "default"
							else
								self.consecutive_hits = self.consecutive_hits + 1

								if self.consecutive_hits < 3 then
									override_damage_profile = current_action.initial_damage_profile or current_action.damage_profile or "default"
								end
							end

							first_person_extension:play_hud_sound_event("staff_beam_hit_enemy", nil, false)

							local check_buffs = self._num_hits > 1

							DamageUtils.process_projectile_hit(world, self.item_name, owner_unit, is_server, result, current_action, direction, check_buffs, nil, nil, self._is_critical_strike, power_level, override_damage_profile)

							self._num_hits = self._num_hits + 1

							if not Managers.player:owner(self.owner_unit).bot_player then
								Managers.state.controller_features:add_effect("rumble", {
									rumble_effect = "hit_character_light"
								})
							end

							if health_extension:is_alive() then
								local overcharge_amount = PlayerUnitStatusSettings.overcharge_values[current_action.overcharge_type]

								if is_critical_strike and buff_extension:has_buff_perk("no_overcharge_crit") then
									overcharge_amount = 0
								end

								self.overcharge_extension:add_charge(overcharge_amount * self.ramping_interval)
							end
						end
					end

					self.damage_timer = self.damage_timer + dt
					self.current_target = hit_unit
				end
			end
		end

		if self.beam_effect_id then
			local weapon_unit = self.weapon_unit
			local end_of_staff_position = Unit.world_position(weapon_unit, Unit.node(weapon_unit, "fx_muzzle"))
			local distance = Vector3.distance(end_of_staff_position, beam_end_position)
			local beam_direction = Vector3.normalize(end_of_staff_position - beam_end_position)
			local rotation = Quaternion.look(beam_direction)

			World.move_particles(world, self.beam_effect_id, beam_end_position, rotation)
			World.set_particles_variable(world, self.beam_effect_id, self.beam_effect_length_id, Vector3(0.3, distance, 0))
			World.move_particles(world, self.beam_end_effect_id, beam_end_position, rotation)
		end
	end
end)
