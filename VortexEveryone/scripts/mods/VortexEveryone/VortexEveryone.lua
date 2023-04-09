-- luacheck: max_line_length 999
-- luacheck: globals get_mod ActionCareerTrueFlightAim PhysicsWorld Actor AiUtils Managers PlayerBotBase ALIVE
-- luacheck: globals Script SummonedVortexExtension ScriptUnit Vector3 POSITION_LOOKUP PlayerUnitMovementSettings
-- luacheck: globals BLACKBOARDS StatusUtils Unit Mover DamageUtils LocomotionUtils WeaponHelper math.clamp ConflictUtils
-- luacheck: globals PlayerCharacterStateInVortex VortexTemplates
local mod = get_mod("VortexEveryone")

mod:echo("hi~")

VortexTemplates.spirit_storm.player_rotation_speed = 0.1
VortexTemplates.spirit_storm.player_radius_change_speed = 1
VortexTemplates.spirit_storm.player_ascend_speed = 1.5
VortexTemplates.spirit_storm.player_in_vortex_max_duration = 8
VortexTemplates.spirit_storm.player_eject_height = { 100, 100 }

local IS_IN_FUNC = false

mod:hook_safe(ActionCareerTrueFlightAim, "client_owner_start_action", function(self)
	self.prioritized_breeds["hero_we_thornsister"] = 1
end)

mod:hook(ActionCareerTrueFlightAim, "client_owner_post_update", function(func, self, ...)
	IS_IN_FUNC = true
	func(self, ...)
	IS_IN_FUNC = false
end)

mod:hook(PhysicsWorld, "immediate_raycast_actors", function(func, ...)
	local args = { ... }
	if IS_IN_FUNC then
		if args[7] == "filter_ray_true_flight_hitbox_only" then
			args[7] = "filter_player_ray_projectile"
		end
	end
	local results, num_results = func(unpack(args))
	local ACTOR_INDEX = 4

	if IS_IN_FUNC then
		local player_unit = Managers.player:local_player().player_unit
		local filtered_results = {}
		local filtered_num = 0
		if num_results > 0 then
			for i = 1, num_results do
				local res = results[i]
				local actor = res[ACTOR_INDEX]
				local unit = Actor.unit(actor)
				if unit ~= player_unit then
					table.insert(filtered_results, res)
					filtered_num = filtered_num + 1
				end
			end
		end
		return filtered_results, filtered_num
	end

	return results, num_results
end)

local VORTEX_ESCAPE_DISTANCE = 10
local VORTEX_ESCAPE_RE_EVALUATE_DISTANCE_SQ = 1
local VORTEX_ESCAPE_RE_EVALUATE_REACHED_DISTANCE_SQ = 0.01

mod:hook_origin(
	PlayerBotBase,
	"_should_re_evaluate_vortex_escape",
	function(self, current_position, previous_check_position, navigation_extension, vortex_unit)
		local re_evaluate_destination = false
		local escape_completed = nil

		if ALIVE[vortex_unit] then
			local vortex_extension = ScriptUnit.extension(vortex_unit, "ai_supplementary_system")
				or ScriptUnit.extension(vortex_unit, "area_damage_system")
			if not vortex_extension then
				mod:dump(ScriptUnit.extensions(vortex_unit), "EXTENSIONS", 1)
				return true
			end
			escape_completed = not vortex_extension:is_position_inside(current_position, VORTEX_ESCAPE_DISTANCE)
		else
			escape_completed = true
		end

		if not escape_completed then
			local traversed_distance_sq = Vector3.distance_squared(previous_check_position, current_position)
			local destination_reached = navigation_extension:destination_reached()
			re_evaluate_destination = VORTEX_ESCAPE_RE_EVALUATE_DISTANCE_SQ <= traversed_distance_sq
				or (destination_reached and VORTEX_ESCAPE_RE_EVALUATE_REACHED_DISTANCE_SQ <= traversed_distance_sq)
		end

		return re_evaluate_destination, escape_completed
	end
)

mod:hook(PlayerBotBase, "_update_vortex_escape", function(func, self, ...)
	local status_extension = self._status_extension
	local blackboard = self._blackboard
	local vortex_unit = status_extension.near_vortex_unit or blackboard.vortex_escape_unit
	local vortex_position = POSITION_LOOKUP[vortex_unit]
	if not vortex_unit or not vortex_position then
		blackboard.near_vortex_unit = nil
		blackboard.navigation_vortex_escape_destination_override = Vector3Box()
		blackboard.use_vortex_escape_destination = false
		blackboard.vortex_escape_unit = nil
		return
	end
	return func(self, ...)
end)

mod:hook_origin(PlayerCharacterStateInVortex, "on_enter", function(self, unit, input, dt, context, t, previous_state)
	local game = Managers.state.network:game()
	self.game = game
	local unit_storage = self.unit_storage
	local status_extension = self.status_extension
	local vortex_unit = status_extension.in_vortex_unit
	local vortex_go_id = unit_storage:go_id(vortex_unit)
	local vortex_extension = ScriptUnit.extension(vortex_unit, "ai_supplementary_system")
		or ScriptUnit.extension(vortex_unit, "area_damage_system")
	local vortex_template = vortex_extension.vortex_template
	self.vortex_unit = vortex_unit
	self.vortex_unit_go_id = vortex_go_id
	self.vortex_owner_unit = vortex_extension._owner_unit
	local player_actions_allowed = vortex_template.player_actions_allowed
	self.vortex_full_inner_radius = vortex_template.full_inner_radius
	self.ascend_speed = vortex_template.player_ascend_speed
	self.rotation_speed = vortex_template.player_rotation_speed
	self.radius_change_speed = vortex_template.player_radius_change_speed
	self.force_player_look_dir_to_spinn_dir = vortex_template.force_player_look_dir_to_spinn_dir
	self.player_actions_allowed = player_actions_allowed
	self.vortex_max_height = vortex_template.max_height
	local interactor_extension = self.interactor_extension

	interactor_extension:abort_interaction()

	local locomotion_extension = self.locomotion_extension

	locomotion_extension:set_maximum_upwards_velocity(10)
	locomotion_extension:enable_drag(false)

	local first_person_extension = self.first_person_extension
	self.screenspace_effect_particle_id = first_person_extension:create_screen_particles(
		"fx/screenspace_inside_plague_vortex"
	)

	first_person_extension:play_hud_sound_event("sfx_player_in_vortex_true")

	local animation_event = nil

	if player_actions_allowed then
		animation_event = "idle"
	else
		local inventory_extension = self.inventory_extension
		local career_extension = self.career_extension

		CharacterStateHelper.stop_weapon_actions(inventory_extension, "stunned")
		CharacterStateHelper.stop_career_abilities(career_extension, "stunned")

		local direction = "backward"
		local directions = PlayerUnitMovementSettings.catapulted.directions
		animation_event = directions[direction].start_animation

		first_person_extension:hide_weapons("in_vortex")

		local include_local_player = false

		CharacterStateHelper.show_inventory_3p(unit, false, include_local_player, self.is_server, inventory_extension)
	end

	CharacterStateHelper.play_animation_event(unit, animation_event)
	CharacterStateHelper.play_animation_event_first_person(first_person_extension, animation_event)
end)

mod:hook_safe(SummonedVortexExtension, "extensions_ready", function(self)
	self.vortex_data.players_inside = {}
	self.vortex_data.players_ejected = {}
end)

mod:hook_safe(
	SummonedVortexExtension,
	"attract",
	function(self, unit, t, dt, vortex_template, vortex_data, center_pos, inner_radius, outer_radius)
		local minimum_height_diff = -0.5
		local falloff_radius = outer_radius - inner_radius
		local max_allowed_inner_radius_dist = vortex_template.max_allowed_inner_radius_dist
		local allowed_distance = inner_radius + max_allowed_inner_radius_dist
		local blackboard = {
			nav_world = self.nav_world,
			breed = {
				name = "poop",
			},
		}
		self:_update_attract_players(
			unit,
			blackboard,
			vortex_data,
			vortex_template,
			t,
			center_pos,
			minimum_height_diff,
			inner_radius,
			outer_radius,
			falloff_radius,
			allowed_distance
		)
	end
)

mod:hook(SummonedVortexExtension, "destroy", function(func, self)
	local vortex_data = self.vortex_data
	local players_inside = vortex_data.players_inside

	mod:dump(vortex_data, "VORTEX DATA", 3)

	for player, _ in pairs(players_inside) do
		mod:echo(player)
		StatusUtils.set_in_vortex_network(player, false, nil)
	end
	return func(self)
end)

local position_lookup = POSITION_LOOKUP
local NUM_SEGMENTS = 4
local EJECT_SEGMENT_LIST = Script.new_array(NUM_SEGMENTS)

SummonedVortexExtension._update_attract_players = function(
	self,
	unit,
	blackboard,
	vortex_data,
	vortex_template,
	t,
	center_pos,
	minimum_height_diff,
	inner_radius,
	outer_radius,
	falloff_radius,
	allowed_distance
)
	local nav_world = blackboard.nav_world
	local physics_world = vortex_data.physics_world
	local vortex_height = vortex_data.height
	local players_inside = vortex_data.players_inside
	local players_ejected = vortex_data.players_ejected
	local player_eject_speed = vortex_template.player_eject_speed
	local player_attract_speed = vortex_template.player_attract_speed
	local eject_distance = vortex_template.player_eject_distance
	local player_gravity = PlayerUnitMovementSettings.gravity_acceleration
	local player_collision_filter = "filter_player_mover"
	local land_test_above = 15
	local land_test_below = 15
	local epsilon_up = Vector3.up() * 0.05
	local near_vortex_distance = outer_radius + 2
	local sides = Managers.state.side:sides()

	for k = 1, #sides, 1 do
		local side = sides[k]
		local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
		local num_player_and_bots = #player_and_bot_units

		for i = 1, num_player_and_bots, 1 do
			local player_unit = player_and_bot_units[i]
			local player_blackboard = BLACKBOARDS[player_unit]
			local player_breed = player_blackboard.breed
			local target_status_extension = ScriptUnit.extension(player_unit, "status_system")
			local valid_vortex_target = player_breed.vortexable and target_status_extension:is_valid_vortex_target()
			local locomotion_extension = ScriptUnit.extension(player_unit, "locomotion_system")
			local player_position = position_lookup[player_unit]
			local suck_dir = center_pos - player_position
			local height = -suck_dir.z

			Vector3.set_z(suck_dir, 0)

			local player_distance = Vector3.length(suck_dir)

			if not target_status_extension.near_vortex and player_distance < near_vortex_distance then
				StatusUtils.set_near_vortex_network(player_unit, true, unit)
			elseif target_status_extension.near_vortex_unit == unit and near_vortex_distance <= player_distance then
				StatusUtils.set_near_vortex_network(player_unit, false)
			end

			if players_inside[player_unit] then
				mod:echo("player inside")
				local vortex_eject_height = players_inside[player_unit].vortex_eject_height
				local vortex_eject_time = players_inside[player_unit].vortex_eject_time
				local mover = Unit.mover(player_unit)
				local side_collides = Mover.collides_sides(mover)

				if side_collides then
					if not target_status_extension.smacked_into_wall then
						target_status_extension.smacked_into_wall = t + 0.7
						local player_velocity = locomotion_extension:current_velocity()
						local player_velocity_normalized = Vector3.normalize(player_velocity)
						local breed_name = blackboard.breed.name
						local impact_damage = DamageUtils.calculate_damage(vortex_template.damage, player_unit, unit)

						DamageUtils.add_damage_network(
							player_unit,
							unit,
							impact_damage,
							"torso",
							"cutting",
							nil,
							-player_velocity_normalized,
							breed_name,
							nil,
							nil,
							nil,
							vortex_template.hit_react_type
						)
					end
				elseif target_status_extension.smacked_into_wall and target_status_extension.smacked_into_wall < t then
					target_status_extension.smacked_into_wall = false
				end

				if not valid_vortex_target or allowed_distance < player_distance then
					mod:echo("in 1")
					StatusUtils.set_in_vortex_network(player_unit, false, nil)

					players_inside[player_unit] = nil
					vortex_data.num_players_inside = vortex_data.num_players_inside - 1
				elseif vortex_eject_height < height or vortex_height < height or vortex_eject_time < t then
					mod:echo("Eject time!")
					local current_velocity = locomotion_extension:current_velocity()
					local velocity_normalized = Vector3.normalize(current_velocity)
					local wanted_landing_position = LocomotionUtils.pos_on_mesh(
						nav_world,
						player_position + velocity_normalized * eject_distance,
						land_test_above,
						land_test_below
					)

					if wanted_landing_position then
						local success, velocity = WeaponHelper.test_angled_trajectory(
							physics_world,
							player_position,
							wanted_landing_position + epsilon_up,
							-player_gravity,
							player_eject_speed,
							nil,
							EJECT_SEGMENT_LIST,
							NUM_SEGMENTS,
							player_collision_filter
						)

						if success then
							StatusUtils.set_in_vortex_network(player_unit, false, nil)
							StatusUtils.set_catapulted_network(player_unit, true, velocity)

							players_inside[player_unit] = nil
							players_ejected[player_unit] = -1
							vortex_data.num_players_inside = vortex_data.num_players_inside - 1
						end
					end
				end
			elseif players_ejected[player_unit] then
				mod:echo("in 3")
				local bliss_time = players_ejected[player_unit]

				if bliss_time < 0 then
					if not target_status_extension:is_catapulted() then
						if player_distance < outer_radius then
							local edge_distance = outer_radius - player_distance
							local time_multiplier = edge_distance / outer_radius
							players_ejected[player_unit] = t
								+ 0.5
								+ vortex_template.player_ejected_bliss_time * 0.5
								+ vortex_template.player_ejected_bliss_time * time_multiplier * 0.5
						else
							players_ejected[player_unit] = t + 0.5 + vortex_template.player_ejected_bliss_time
						end
					end
				elseif bliss_time < t then
					players_ejected[player_unit] = nil
				end
			elseif
				valid_vortex_target
				and not target_status_extension:is_in_vortex()
				and player_distance < outer_radius
				and minimum_height_diff <= height
				and height < vortex_height
			then
				mod:echo("in 4")
				if inner_radius < player_distance then
					local distance_to_inner_radius = player_distance - inner_radius
					local k = math.clamp(1 - distance_to_inner_radius / falloff_radius, 0, 1)
					local speed = player_attract_speed * k * k
					local dir = Vector3.normalize(suck_dir)

					locomotion_extension:add_external_velocity(dir * speed)
				else
					mod:echo("IN VORTEX")
					StatusUtils.set_in_vortex_network(player_unit, true, unit)

					local vortex_eject_height = ConflictUtils.random_interval(vortex_template.player_eject_height)
					players_inside[player_unit] = {
						vortex_eject_height = vortex_eject_height,
						vortex_eject_time = t + vortex_template.player_in_vortex_max_duration,
					}
					vortex_data.num_players_inside = vortex_data.num_players_inside + 1
				end
			end
		end
	end
end
