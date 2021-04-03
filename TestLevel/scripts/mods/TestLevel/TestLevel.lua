-- luacheck: globals get_mod LevelSettings Managers NetworkLookup PackageManager LevelResource Level World AdventureSpawning
local mod = get_mod("TestLevel")

local level_name = "test_level"
-- local level_package_name = "resource_packages/TestLevel/test_level"
-- local path_to_level = "content/levels/test_level"
-- local path_to_level = "content/levels/de_dust2"

local level_package_name = "resource_packages/TestLevel/NoDepsLevel"
local path_to_level = "test_level/world"

LevelSettings[level_name] = {
    conflict_settings = "level_editor",
    no_terror_events = true,
    package_name = level_package_name,
    player_aux_bus_name = "environment_reverb_outside",
    environment_state = "exterior",
    knocked_down_setting = "knocked_down",
    ambient_sound_event = "silent_default_world_sound",
    level_name = path_to_level,
    level_image = "level_image_any",
    loading_ui_package_name = "loading_screen_1",
    display_name = "test_level",
    source_aux_bus_name = "environment_reverb_outside_source",
    level_particle_effects = {},
    level_screen_effects = {},
    locations = {}
}

mod.level_id = mod.level_id or #NetworkLookup.level_keys + 1
NetworkLookup.level_keys[mod.level_id] = level_name
NetworkLookup.level_keys[level_name] = mod.level_id

mod:command("test_level", "Load into the test level", function()
    Managers.state.game_mode:start_specific_level("test_level")
end)

mod:hook(PackageManager, "load", function(func, self, package_name, reference_name, callback, asynchronous, prioritize)
    if package_name == level_package_name then
        -- Load the keep in sync with out package because we use it's shading environment
        Managers.package:load("resource_packages/levels/inn", "TestLevel", nil, true)
        return mod:load_package(package_name)
    else
        return func(self, package_name, reference_name, callback, asynchronous, prioritize)
    end
end)

mod:hook(PackageManager, "has_loaded", function(func, self, package_name, reference_name)
    if package_name == level_package_name then
        -- Load the keep in sync with out package because we use it's shading environment
        local inn_loaded = Managers.package:has_loaded("resource_packages/levels/inn", "TestLevel")
        return inn_loaded and mod:package_status(package_name) == "loaded"
    else
        return func(self, package_name, reference_name)
    end
end)

mod:hook(PackageManager, "unload", function(func, self, package_name, reference_name)
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

for k, v in pairs(PlayerBreeds) do
    PlayerBreeds[k].armor_category = 1
end

for k, v in pairs(DifficultySettings) do
    DifficultySettings[k].friendly_fire_melee = true
    DifficultySettings[k].friendly_fire_ranged = true
    DifficultySettings[k].allows_respawns = true
    DifficultySettings[k].wounds = 1
    DifficultySettings[k].respawn = {
        temporary_health_percentage = 0,
        health_percentage = 1,
        ammo_melee = 1,
        ammo_ranged = 1
    }
    DifficultySettings[k].friendly_fire_multiplier = 2

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

local function weapon_printf(...)
    if script_data.debug_weapons then
        print("[ActionSweep] " .. sprintf(...))
    end
end

local BAKED_SWEEP_TIME = 1
local BAKED_SWEEP_POS = 2
local BAKED_SWEEP_ROT = 5

local function _get_baked_pose(time, data)
    local num_data = #data

    for i = 1, num_data, 1 do
        local current = data[i]
        local next = data[math.min(i + 1, num_data)]

        if current == next or (i == 1 and time <= current[BAKED_SWEEP_TIME]) then
            local loc = Vector3(current[BAKED_SWEEP_POS], current[BAKED_SWEEP_POS + 1], current[BAKED_SWEEP_POS + 2])
            local rot = Quaternion.from_elements(current[BAKED_SWEEP_ROT], current[BAKED_SWEEP_ROT + 1],
                            current[BAKED_SWEEP_ROT + 2], current[BAKED_SWEEP_ROT + 3])

            return Matrix4x4.from_quaternion_position(rot, loc)
        elseif current[BAKED_SWEEP_TIME] <= time and time <= next[BAKED_SWEEP_TIME] then
            local time_range = math.max(next[BAKED_SWEEP_TIME] - current[BAKED_SWEEP_TIME], 0.0001)
            local lerp_t = (time - current[BAKED_SWEEP_TIME]) / time_range
            local start_position = Vector3(current[BAKED_SWEEP_POS], current[BAKED_SWEEP_POS + 1],
                                       current[BAKED_SWEEP_POS + 2])
            local start_rotation = Quaternion.from_elements(current[BAKED_SWEEP_ROT], current[BAKED_SWEEP_ROT + 1],
                                       current[BAKED_SWEEP_ROT + 2], current[BAKED_SWEEP_ROT + 3])
            local end_position = Vector3(next[BAKED_SWEEP_POS], next[BAKED_SWEEP_POS + 1], next[BAKED_SWEEP_POS + 2])
            local end_rotation = Quaternion.from_elements(next[BAKED_SWEEP_ROT], next[BAKED_SWEEP_ROT + 1],
                                     next[BAKED_SWEEP_ROT + 2], next[BAKED_SWEEP_ROT + 3])
            local current_position = Vector3.lerp(start_position, end_position, lerp_t)
            local current_rotation = Quaternion.lerp(start_rotation, end_rotation, lerp_t)

            return Matrix4x4.from_quaternion_position(current_rotation, current_position)
        end
    end

    return nil, nil
end

local function get_baked_data_name(action_hand)
    if action_hand then
        return "baked_sweep_" .. action_hand
    else
        return "baked_sweep"
    end
end

local SWEEP_RESULTS = {}

local function calculate_attack_direction(action, weapon_rotation)
    local quaternion_axis = action.attack_direction or "forward"
    local attack_direction = Quaternion[quaternion_axis](weapon_rotation)

    return (action.invert_attack_direction and -attack_direction) or attack_direction
end

ActionSweep.client_owner_start_action = function(self, new_action, t, chain_action_data, power_level, action_init_data)
    ActionSweep.super.client_owner_start_action(self, new_action, t, chain_action_data, power_level, action_init_data)

    self._has_played_rumble_effect = false
    self._current_action = new_action
    self._action_time_started = t
    self._has_hit_environment = false
    self._has_hit_precision_target = true
    self._precision_target_unit = nil
    self._number_of_hit_enemies = 0
    self._amount_of_mass_hit = 0
    self._number_of_potential_hit_results = 0
    self._hit_mass_of_potential_hit_results = 0
    self._network_manager = Managers.state.network
    self._last_potential_hit_result_has_result = false
    self._last_potential_hit_result = {}
    local owner_unit = self.owner_unit
    local buff_extension = ScriptUnit.extension(owner_unit, "buff_system")
    local hud_extension = ScriptUnit.has_extension(owner_unit, "hud_system")
    self._owner_buff_extension = buff_extension
    self._owner_hud_extension = hud_extension
    local anim_time_scale = ActionUtils.get_action_time_scale(owner_unit, new_action)
    self._anim_time_scale = anim_time_scale
    self._time_to_hit = t + (new_action.hit_time or 0) / anim_time_scale
    local action_hand = action_init_data and action_init_data.action_hand
    local damage_profile_name = self:_get_damage_profile_name(action_hand, new_action)
    self._action_hand = action_hand
    self._baked_sweep_data = new_action[get_baked_data_name(self._action_hand)]
    self._baked_data_dt_recip = (self._baked_sweep_data and 1 / #self._baked_sweep_data) or 1
    self._damage_profile_id = NetworkLookup.damage_profiles[damage_profile_name]
    local damage_profile = DamageProfileTemplates[damage_profile_name]
    self._damage_profile = damage_profile
    self._has_starting_melee_boost = nil
    self._starting_melee_boost_curve_multiplier = nil
    local has_melee_boost, _ = self:_get_power_boost()
    local is_critical_strike = ActionUtils.is_critical_strike(owner_unit, new_action, t) or has_melee_boost
    local difficulty_level = Managers.state.difficulty:get_difficulty()
    local cleave_power_level = ActionUtils.scale_power_levels(power_level, "cleave", owner_unit, difficulty_level)
    cleave_power_level = buff_extension:apply_buffs_to_value(cleave_power_level, "power_level_melee")
    cleave_power_level = buff_extension:apply_buffs_to_value(cleave_power_level, "power_level_melee_cleave")
    self._power_level = power_level
    local max_targets_attack, max_targets_impact = ActionUtils.get_max_targets(damage_profile, cleave_power_level)
    max_targets_attack = buff_extension:apply_buffs_to_value(max_targets_attack or 1, "increased_max_targets")
    max_targets_impact = buff_extension:apply_buffs_to_value(max_targets_impact or 1, "increased_max_targets")

    if buff_extension:has_buff_type("armor penetration") then
        max_targets_impact = max_targets_impact * 2
    end

    self._max_targets_attack = max_targets_attack
    self._max_targets_impact = max_targets_impact
    self._max_targets = (max_targets_impact < max_targets_attack and max_targets_attack) or max_targets_impact
    self._down_offset = new_action.sweep_z_offset or 0.1
    self._auto_aim_reset = false

    if not Managers.player:owner(self.owner_unit).bot_player and damage_profile.charge_value == "heavy_attack" then
        Managers.state.controller_features:add_effect("rumble", {
            rumble_effect = "light_swing"
        })
    end

    local first_person_unit = self.first_person_unit

    if global_is_inside_inn then
        self._down_offset = 0
    end

    self._attack_aborted = false
    self._send_delayed_hit_rpc = false

    table.clear(self._hit_units)
    buff_extension:trigger_procs("on_sweep")

    self._ignore_mass_and_armour = buff_extension:has_buff_type("ignore_mass_and_armour")
    local first_person_extension = ScriptUnit.extension(owner_unit, "first_person_system")

    self:_handle_critical_strike(is_critical_strike, buff_extension, hud_extension, first_person_extension,
        "on_critical_sweep", "Play_player_combat_crit_swing_2D")

    self._is_critical_strike = is_critical_strike
    self._started_damage_window = false

    unit_flow_event(first_person_unit, "sfx_swing_started")

    if new_action.use_precision_sweep then
        first_person_extension:disable_rig_movement()

        local physics_world = World.get_data(self.world, "physics_world")
        local pos = first_person_extension:current_position()
        local rot = first_person_extension:current_rotation()
        local direction = Quaternion.forward(rot)
        -- local collision_filter = "filter_melee_sweep"
        local collision_filter = "filter_player_ray_projectile"
        local results = PhysicsWorld.immediate_raycast(physics_world, pos, direction, new_action.dedicated_target_range,
                            "all", "collision_filter", collision_filter)

        if results then
            local side = Managers.state.side.side_by_unit[owner_unit]
            local enemy_units_lookup = side.enemy_units_lookup
            local num_results = #results

            for i = 1, num_results, 1 do
                local result = results[i]
                local actor = result[4]
                local hit_unit = Actor.unit(actor)
                local breed = unit_get_data(hit_unit, "breed")
                local friendly_fire = false

                -- Removed check for ff
                if breed then
                    local node = actor_node(actor)
                    local hit_zone = breed.hit_zones_lookup[node]
                    local hit_zone_name = hit_zone.name

                    if hit_zone_name ~= "afro" then
                        local target_health_extension = ScriptUnit.extension(hit_unit, "health_system")

                        if target_health_extension:is_alive() then
                            self._precision_target_unit = hit_unit
                            self._has_hit_precision_target = false

                            break
                        end
                    end
                end
            end
        end

        if not self._precision_target_unit and ScriptUnit.has_extension(owner_unit, "smart_targeting_system") then
            local targeting_extension = ScriptUnit.extension(owner_unit, "smart_targeting_system")
            local targeting_data = targeting_extension:get_targeting_data()
            local smart_targeting_unit = targeting_data.unit
            local target_health_extension = smart_targeting_unit and
                                                ScriptUnit.has_extension(smart_targeting_unit, "health_system")

            if smart_targeting_unit and target_health_extension and target_health_extension:is_alive() then
                self._precision_target_unit = smart_targeting_unit
                self._has_hit_precision_target = false
            end
        end
    end

    local weapon_unit = self.weapon_unit
    local rotation = unit_world_rotation(weapon_unit, 0)
    local weapon_up_dir = Quaternion.up(rotation)
    local weapon_up_offset_mod = new_action.weapon_up_offset_mod or 0
    local weapon_up_offset = weapon_up_dir * weapon_up_offset_mod
    local actual_position_initial = POSITION_LOOKUP[weapon_unit]
    local position_initial = Vector3(actual_position_initial.x, actual_position_initial.y,
                                 actual_position_initial.z - self._down_offset) + weapon_up_offset

    self._stored_position:store(position_initial)
    self._stored_rotation:store(rotation)

    self._could_damage_last_update = false

    if new_action.lookup_data.sub_action_name == "assassinate" then
        local buff = buff_extension:get_non_stacking_buff("assassinate")

        buff_extension:remove_buff(buff.id)
    end
end

ActionSweep._do_overlap = function(self, dt, t, unit, owner_unit, current_action, physics_world,
    is_within_damage_window, current_position, current_rotation)
    if self._attack_aborted then
        return
    end

    local current_rot_up = Quaternion.up(current_rotation)
    local hit_environment_rumble = false
    local network_manager = self._network_manager
    local weapon_system = self.weapon_system
    local weapon_up_dir = Quaternion.up(current_rotation)
    local weapon_up_offset_mod = current_action.weapon_up_offset_mod or 0
    local weapon_up_offset = weapon_up_dir * weapon_up_offset_mod

    if not is_within_damage_window and not self._could_damage_last_update then
        local actual_last_position_current = current_position
        local last_position_current = Vector3(actual_last_position_current.x, actual_last_position_current.y,
                                          actual_last_position_current.z - self._down_offset) + weapon_up_offset

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
    local position_current = Vector3(actual_position_current.x, actual_position_current.y,
                                 actual_position_current.z - self._down_offset) + weapon_up_offset
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
    local position_end = (position_previous + current_rot_up * weapon_half_length * 2) -
                             Quaternion.up(rotation_previous) * weapon_half_length
    local max_num_hits1 = 5
    local max_num_hits2 = 20
    local max_num_hits3 = 5
    local attack_direction = calculate_attack_direction(current_action, weapon_rot)
    local owner_player = Managers.player:owner(owner_unit)
    local weapon_cross_section = Vector3(weapon_half_extents.x, weapon_half_extents.y, 0.0001)
    local difficulty_rank = Managers.state.difficulty:get_difficulty_rank()
    -- local collision_filter = "filter_melee_sweep"
    local collision_filter = "filter_player_ray_projectile"

    if PhysicsWorld.start_reusing_sweep_tables then
        PhysicsWorld.start_reusing_sweep_tables()
    end

    local sweep_results1 = PhysicsWorld.linear_obb_sweep(physics_world, position_previous, position_previous +
                               weapon_up_dir_previous * weapon_half_length * 2, weapon_cross_section, rotation_previous,
                               max_num_hits1, "collision_filter", collision_filter, "report_initial_overlap")
    local sweep_results2 = PhysicsWorld.linear_obb_sweep(physics_world, position_start, position_end,
                               weapon_half_extents, rotation_previous, max_num_hits2, "collision_filter",
                               collision_filter, "report_initial_overlap")
    local sweep_results3 = PhysicsWorld.linear_obb_sweep(physics_world,
                               position_previous + current_rot_up * weapon_half_length,
                               position_current + current_rot_up * weapon_half_length, weapon_half_extents,
                               rotation_current, max_num_hits3, "collision_filter", collision_filter,
                               "report_initial_overlap")
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
        local this_frames_precision_target = self:check_precision_target(owner_unit, owner_player,
                                                 current_action.dedicated_target_range, true, weapon_furthest_point)

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
        local has_hit_precision_target_and_has_last_hit_result =
            has_potential_result and (has_hit_precision_target or lost_precision_target)
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
            fassert(Vector3.is_valid(hit_position), "The hit position is not valid! Actor: %s, Unit: %s", hit_actor,
                hit_unit)
            assert(hit_unit, "hit_unit is nil.")

            hit_unit, hit_actor = ActionUtils.redirect_shield_hit(hit_unit, hit_actor)
            local breed = AiUtils.unit_breed(hit_unit)
            local is_dodging = false
            local in_view = first_person_extension:is_within_custom_view(hit_position, view_position, view_rotation,
                                action_hitbox_vertical_fov, action_hitbox_horizontal_fov)
            local is_character = breed ~= nil
            local hit_self = hit_unit == owner_unit
            local is_friendly_fire = false
            local shield_blocked = false

            if breed and breed.can_dodge then
                is_dodging = AiUtils.attack_is_dodged(hit_unit)
            end

            -- remove ff check
            if is_character and not hit_self and in_view and
                (has_hit_precision_target_and_has_last_hit_result or self._hit_units[hit_unit] == nil) then
                hit_units[hit_unit] = true
                local status_extension = self._status_extension
                shield_blocked = is_dodging or
                                     (AiUtils.attack_is_shield_blocked(hit_unit, owner_unit) and
                                         not current_action.ignore_armour_hit and not self._ignore_mass_and_armour and
                                         not status_extension:is_invisible())
                local target_health_extension = ScriptUnit.extension(hit_unit, "health_system")
                local can_damage = false
                local can_stagger = false
                local hit_unit_id = network_manager:unit_game_object_id(hit_unit)
                local actual_hit_target_index = 1
                local target_settings = nil

                if current_action.use_precision_sweep and self._precision_target_unit ~= nil and
                    not self._has_hit_precision_target and not final_frame then
                    if hit_unit == self._precision_target_unit then
                        self._has_hit_precision_target = true
                        actual_hit_target_index, shield_blocked, can_damage, can_stagger =
                            self:_calculate_hit_mass(difficulty_rank, target_health_extension, actual_hit_target_index,
                                shield_blocked, current_action, breed, hit_unit_id)
                        target_settings = damage_profile.default_target
                    elseif target_health_extension:is_alive() then
                        local potential_target_hit_mass = self:_get_target_hit_mass(difficulty_rank, shield_blocked,
                                                              current_action, breed, hit_unit_id)
                        local num_potential_hits = self._number_of_potential_hit_results + 1
                        local result_to_save = {}
                        self._last_potential_hit_result_has_result = true
                        result_to_save.hit_unit = hit_unit
                        result_to_save.actor = ActorBox(hit_actor)
                        result_to_save.hit_position = Vector3Box(hit_position)
                        result_to_save.hit_normal = Vector3Box(hit_normal)
                        result_to_save.hit_mass_budget = self._max_targets -
                                                             (self._amount_of_mass_hit + potential_target_hit_mass) >= 0
                        self._last_potential_hit_result[num_potential_hits] = result_to_save
                        self._number_of_potential_hit_results = num_potential_hits
                    end
                elseif self._amount_of_mass_hit < self._max_targets or has_hit_precision_target_and_has_last_hit_result then
                    if not is_friendly_fire then
                        actual_hit_target_index, shield_blocked, can_damage, can_stagger =
                            self:_calculate_hit_mass(difficulty_rank, target_health_extension, actual_hit_target_index,
                                shield_blocked, current_action, breed, hit_unit_id)
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
                        hit_armor = (target_health_extension:is_alive() and
                                        (breed.armor_category == 2 or breed.stagger_armor_category == 2)) or
                                        breed.armor_category == 3
                    else
                        hit_zone_name = "torso"
                    end

                    local abort_attack = self._max_targets <= self._number_of_hit_enemies or
                                             (self._max_targets <= self._amount_of_mass_hit and
                                                 not self._ignore_mass_and_armour) or
                                             (hit_armor and not current_action.slide_armour_hit and
                                                 not current_action.ignore_armour_hit and
                                                 not self._ignore_mass_and_armour)

                    if shield_blocked then
                        abort_attack = self._max_targets <= self._amount_of_mass_hit + 3 or
                                           (hit_armor and not current_action.slide_armour_hit and
                                               not current_action.ignore_armour_hit and not self._ignore_mass_and_armour)
                    end

                    local armor_type = breed.armor_category

                    self:_play_hit_animations(owner_unit, current_action, abort_attack, hit_zone_name, armor_type,
                        shield_blocked)

                    if sound_effect_extension and AiUtils.unit_alive(hit_unit) then
                        sound_effect_extension:add_hit()
                    end

                    local damage_source = self.item_name
                    local damage_source_id = NetworkLookup.damage_sources[damage_source]
                    local attacker_unit_id = network_manager:unit_game_object_id(owner_unit)
                    local hit_zone_id = NetworkLookup.hit_zones[hit_zone_name]
                    local is_server = self.is_server
                    local backstab_multiplier = self:_check_backstab(breed, nil, hit_unit, owner_unit, buff_extension,
                                                    first_person_extension)

                    if breed and not is_dodging then
                        local has_melee_boost, melee_boost_curve_multiplier = self:_get_power_boost()
                        local power_level = self._power_level
                        local is_critical_strike = self._is_critical_strike or has_melee_boost

                        self:_play_character_impact(is_server, owner_unit, hit_unit, breed, hit_position, hit_zone_name,
                            current_action, damage_profile, actual_hit_target_index, power_level, attack_direction,
                            shield_blocked, melee_boost_curve_multiplier, is_critical_strike, backstab_multiplier)
                    end

                    if is_dodging then
                        abort_attack = false
                    end

                    if Managers.state.controller_features and self.owner.local_player and
                        not self._has_played_rumble_effect then
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
                        if (charge_value == "heavy_attack" and buff_extension:has_buff_perk("shield_break")) or
                            buff_extension:has_buff_type("armor penetration") then
                            shield_break_procc = true
                        end
                    else
                        local send_to_server = true
                        local number_of_hit_enemies = self._number_of_hit_enemies
                        local buff_type = DamageUtils.get_item_buff_type(self.item_name)
                        buff_result = DamageUtils.buff_on_attack(owner_unit, hit_unit, charge_value, is_critical_strike,
                                          hit_zone_name, number_of_hit_enemies, send_to_server, buff_type)
                        local attack_template_id = NetworkLookup.attack_templates[target_settings.attack_template]

                        weapon_system:rpc_weapon_blood(nil, attacker_unit_id, attack_template_id)

                        local blood_position = Vector3(result.position.x, result.position.y,
                                                   result.position.z + self._down_offset)

                        Managers.state.blood:add_enemy_blood(blood_position, hit_unit, target_health_extension)
                    end

                    if buff_result ~= "killing_blow" then
                        self:_send_attack_hit(t, damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id,
                            hit_position, attack_direction, damage_profile_id, "power_level", power_level,
                            "hit_target_index", actual_hit_target_index, "blocking", shield_blocked,
                            "shield_break_procced", shield_break_procc, "boost_curve_multiplier",
                            melee_boost_curve_multiplier, "is_critical_strike", is_critical_strike, "can_damage",
                            can_damage, "can_stagger", can_stagger, "backstab_multiplier", backstab_multiplier,
                            "first_hit", self._number_of_hit_enemies == 1)

                        if not shield_blocked and not self.is_server then
                            local attack_template_id = NetworkLookup.attack_templates[target_settings.attack_template]

                            network_manager.network_transmit:send_rpc_server("rpc_weapon_blood", attacker_unit_id,
                                attack_template_id)
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

                    if Managers.state.controller_features and self.owner.local_player and
                        not self._has_played_rumble_effect then
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
                        self:hit_level_object(hit_units, hit_unit, owner_unit, current_action, hit_position,
                            attack_direction, level_index, true, hit_actor)
                        self:_play_environmental_effect(current_rotation, current_action, hit_unit, hit_position,
                            hit_normal, hit_actor)

                        hit_environment_rumble = true
                        local is_armored = hit_unit_armor and hit_unit_armor == 2
                        local abort_attack = self._max_targets <= self._number_of_hit_enemies or
                                                 ((is_armored or self._max_targets <= self._amount_of_mass_hit) and
                                                     not current_action.slide_armour_hit and
                                                     not self._ignore_mass_and_armour)

                        self:_play_hit_animations(owner_unit, current_action, abort_attack)

                        if abort_attack then
                            break
                        end
                    elseif is_level_unit then
                        self:hit_level_object(hit_units, hit_unit, owner_unit, current_action, hit_position,
                            attack_direction, level_index, false)
                        self:_play_environmental_effect(current_rotation, current_action, hit_unit, hit_position,
                            hit_normal, hit_actor)

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
                            self:_send_attack_hit(t, damage_source_id, attacker_unit_id, hit_unit_id, hit_zone_id,
                                hit_position, attack_direction, damage_profile_id, "power_level", power_level,
                                "hit_target_index", actual_hit_target_index, "blocking", shield_blocked,
                                "boost_curve_multiplier", melee_boost_curve_multiplier, "is_critical_strike",
                                is_critical_strike)

                            local abort_attack = not unit_get_data(hit_unit, "weapon_hit_through")

                            self:_play_hit_animations(owner_unit, current_action, abort_attack)
                            self:_play_environmental_effect(current_rotation, current_action, hit_unit, hit_position,
                                hit_normal, hit_actor)

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

            self:_play_environmental_effect(current_rotation, current_action, hit_unit, hit_position, hit_normal,
                hit_actor)

            if Managers.state.controller_features and global_is_inside_inn and self.owner.local_player and
                not self._has_played_rumble_effect then
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

    if Managers.state.controller_features and global_is_inside_inn and hit_environment_rumble and
        self.owner.local_player and not self._has_played_rumble_effect then
        Managers.state.controller_features:add_effect("rumble", {
            rumble_effect = "hit_environment"
        })

        self._has_played_rumble_effect = true
    end

    if PhysicsWorld.stop_reusing_sweep_tables then
        PhysicsWorld.stop_reusing_sweep_tables()
    end
end

-- function mod.update()
--     if Managers.time then
--         local t = Managers.time:time("game")
--         if t % 5 then
--             local game_mode = Managers.state.game_mode
--
--             if game_mode then
--                 game_mode:force_respawn_dead_players()
--             end
--         end
--     end
-- end

RespawnHandler.server_update = function(self, dt, t, slots)
    local profile_synchronizer = self._profile_synchronizer
    local all_synced = profile_synchronizer:all_synced()

    for i = 1, #slots, 1 do
        local status = slots[i]
        local data = status.game_mode_data
        local is_dead = data.health_state == "dead"

        if is_dead then
            if not data.ready_for_respawn and not data.respawn_timer then
                local peer_id = status.peer_id
                local local_player_id = status.local_player_id
                local respawn_time = 5

                if peer_id and local_player_id then
                    local player = Managers.player:player(peer_id, local_player_id)
                    local player_unit = player.player_unit

                    if player_unit and Unit.alive(player_unit) then
                        local buff_extension = ScriptUnit.extension(player_unit, "buff_system")
                        respawn_time = buff_extension:apply_buffs_to_value(respawn_time, "faster_respawn")
                    end
                end

                data.respawn_timer = t + respawn_time
            elseif not data.ready_for_respawn and data.respawn_timer < t then
                data.respawn_timer = nil
                data.ready_for_respawn = true
            end
        elseif data.respawn_timer then
            data.respawn_timer = nil
        end

        if all_synced then
            if is_dead and data.ready_for_respawn and status.peer_id then
                local data_respawn_unit = data.respawn_unit
                local respawn_unit = self:get_respawn_unit()
                local respawn_unit_to_use = nil

                if data_respawn_unit and Unit.alive(data_respawn_unit) then
                    respawn_unit_to_use = data_respawn_unit
                else
                    respawn_unit_to_use = respawn_unit
                end

                if respawn_unit_to_use then
                    local respawn_unit_id = Managers.state.network:level_object_id(respawn_unit_to_use)
                    local difficulty_settings = Managers.state.difficulty:get_difficulty_settings()
                    local network_consumables = SpawningHelper.netpack_consumables(data.consumables)

                    Managers.state.network.network_transmit:send_rpc("rpc_to_client_respawn_player", status.peer_id,
                        status.local_player_id, status.profile_index, status.career_index, respawn_unit_id, i,
                        unpack(network_consumables))

                    data.health_state = "respawning"
                    data.respawn_unit = respawn_unit_to_use
                    data.health_percentage = difficulty_settings.respawn.health_percentage
                    data.temporary_health_percentage = difficulty_settings.respawn.temporary_health_percentage
                end
            elseif self._move_players and data.health_state == "respawn" then
                local current_respawn_unit = data.respawn_unit
                local current_respawn_position = Unit.local_position(current_respawn_unit, 0)
                local _, _, _, _, path_index =
                    MainPathUtils.closest_pos_at_main_path(nil, current_respawn_position, nil)
                local ahead_path_index = Managers.state.conflict.main_path_info.current_path_index

                if path_index < ahead_path_index then
                    local peer_id = status.peer_id
                    local local_player_id = status.local_player_id

                    if peer_id and local_player_id then
                        local player = Managers.player:player(peer_id, local_player_id)
                        local player_unit = player.player_unit
                        local player_unit_id = Managers.state.network:unit_game_object_id(player_unit)
                        local locomotion_extension = ScriptUnit.extension(player_unit, "locomotion_system")
                        local new_respawn_unit = self:get_respawn_unit()
                        local position = Unit.local_position(new_respawn_unit, 0)
                        local rotation = Unit.local_rotation(new_respawn_unit, 0)

                        LocomotionUtils.enable_linked_movement(self._world, player_unit, new_respawn_unit, 0,
                            Vector3.zero())
                        locomotion_extension:teleport_to(position, rotation)
                        Managers.state.network.network_transmit:send_rpc_clients("rpc_teleport_unit_to", player_unit_id,
                            position, rotation)
                        self:set_respawn_unit_available(current_respawn_unit)

                        data.respawn_unit = new_respawn_unit
                    end
                end
            end
        end
    end

    if all_synced and self._move_players then
        self._move_players = false
    end
end

mod:hook(RespawnHandler, "get_respawn_unit", function(func, self, ignore_boss_doors)
    local world = Managers.world:world("level_world")
    local spawners = World.units_by_resource(world, "content/models/props/spawner")

    if #spawners > 0 then
        return spawners[math.random(#spawners)]
    end

    return func(self, ignore_boss_doors)
end)

RespawnHandler._respawn_player = function(self, player, profile_index, career_index, respawn_unit, health_kit, potion,
    grenade)
    player:set_profile_index(profile_index)
    player:set_career_index(career_index)

    local position = Unit.local_position(respawn_unit, 0)
    local rotation = Unit.local_rotation(respawn_unit, 0)
    local respawn_settings = Managers.state.difficulty:get_difficulty_settings().respawn
    local ammo_melee = respawn_settings.ammo_melee
    local ammo_ranged = respawn_settings.ammo_ranged
    local unit = player:spawn(position, rotation, false, ammo_melee, ammo_ranged, health_kit, potion, grenade)
    local status_extension = ScriptUnit.extension(unit, "status_system")

    -- status_extension:set_revived(true, false)
    -- status_extension:set_ready_for_assisted_respawn(true, respawn_unit)

    local network_manager = Managers.state.network
    local unit_id = network_manager:unit_game_object_id(unit)
    local respawn_unit_id = network_manager:level_object_id(respawn_unit)

    -- network_manager.network_transmit:send_rpc_server("rpc_status_change_bool", NetworkLookup.statuses.revived, true, unit_id, respawn_unit_id)
    -- network_manager.network_transmit:send_rpc_server("rpc_respawn_confirmed", player:local_player_id())
end

PlayerBreedHitZones.player_breed_hit_zones = {
    full = {
        prio = 3,
        actors = {}
    },
    torso = {
        prio = 2,
        actors = {"c_spine", "c_spine1", "c_spine2", "c_hips", "c_leftshoulder", "c_rightshoulder", "c_leftarm",
                  "c_leftforearm", "c_lefthand", "c_rightarm", "c_rightforearm", "c_righthand", "c_rightupleg",
                  "c_rightleg", "c_rightfoot", "c_leftupleg", "c_leftleg", "c_leftfoot"},
        push_actors = {}
    },
    head = {
        prio = 1,
        actors = {"c_head", "c_neck"}
    },
    afro = {
        prio = 5,
        actors = {"c_afro"}
    }
}
PlayerBreedHitZones.kruber_breed_hit_zones = {
    full = {
        prio = 3,
        actors = {}
    },
    torso = {
        prio = 2,
        actors = {"c_spine", "c_hips", "c_leftshoulder", "c_rightshoulder", "c_leftarm", "c_leftforearm", "c_lefthand",
                  "c_rightarm", "c_rightforearm", "c_righthand", "c_rightupleg", "c_rightleg", "c_rightfoot",
                  "c_leftupleg", "c_leftleg", "c_leftfoot"},
        push_actors = {}
    },
    head = {
        prio = 1,
        actors = {"c_head", "c_neck"}
    },
    afro = {
        prio = 5,
        actors = {"c_afro"}
    }
}

mod:hook(DeathSystem, "kill_unit", function(func, self, unit, killing_blow)
    if self.is_server then
        local pickup_system = Managers.state.entity:system("pickup_system")
        local player_pos = POSITION_LOOKUP[unit] + Vector3.up() * 0.1
        local raycast_down = true
        if math.random(5) == 5 then
            pickup_system:buff_spawn_pickup("frag_grenade_t1", player_pos, raycast_down)
        else
            pickup_system:buff_spawn_pickup("ammo_ranger", player_pos, raycast_down)
        end
    end
    return func(self, unit, killing_blow)
end)

mod:hook_origin(Player, "_set_spawn_state", function(self, state)
    -- fassert(state == "spawned" or state == "queued_for_despawn" or state == "despawned", "Invalid spawn state %s", state)
    -- fassert(Player._allowed_transitions[self._spawn_state][state], "Spawn state transition from %s to %s is not allowed", self._spawn_state, state)

    self._spawn_state = state
end)

Player._allowed_transitions = {
    despawned = {
        spawned = true
    },
    queued_for_despawn = {
        despawned = true,
        queued_for_despawn = true
    },
    spawned = {
        queued_for_despawn = true,
        despawned = true
    }
}

PlayerBot.despawn = function(self)
    if self._spawn_state ~= "despawned" then
        self:_set_spawn_state("despawned")

        local player_unit = self.player_unit

        if Unit.alive(player_unit) then
            Managers.state.unit_spawner:mark_for_deletion(player_unit)
            Managers.telemetry.events:player_despawned(self)
        else
            print("player_bot was already despawned. Should not happen.")
        end
    end
end
