-- luacheck: globals get_mod Vector3 ScriptUnit ALIVE POSITION_LOOKUP Managers
-- luacheck: globals World WwiseWorld WwiseUtils Quaternion Unit BackendInterfaceLiveEventsPlayfab
-- luacheck: globals Math
local mod = get_mod("MutatorUnstableTeleport")
mod:dofile("scripts/mods/MutatorUnstableTeleport/add_mutator_template")

mod:hook(_G, 'Localize', function(func, key, ...)
  if key == "custom_mutator_unstable_teleport" then
    return "Unstable teleporter"
  end
  if key == "description_custom_mutator_unstable_teleport" then
    return "Chaos magic is inteferring with the Bridge of Shadows... Something may go wrong with the teleport, but it should clear itself up on the return journey."
  end
  return func(key, ...)
end)




mod.connected_players = {}
mod.rpc_name = "custom_mutator_unstable_teleport_update_players"
mod:network_register(mod.rpc_name, function(_, connected_player_peer_ids)
  mod.connected_players = {}
  for player1_peer_id, player2_peer_id in pairs(connected_player_peer_ids) do
    local player1 = Managers.player:player_from_peer_id(player1_peer_id)
    local player2 = Managers.player:player_from_peer_id(player2_peer_id)
    mod.connected_players[player1] = player2
  end
end)

function mod.sync_connected_players()
  local connected_player_peer_ids = {}
  for player1_unit, player2_unit in pairs(mod.connected_players) do
    local player1 = Managers.player:unit_owner(player1_unit)
    local player2 = Managers.player:unit_owner(player2_unit)
    connected_player_peer_ids[player1.peer_id] = player2.peer_id
  end
  mod:network_send(mod.rpc_name, "others", connected_player_peer_ids)
end

function mod.on_user_joined()
  mod.sync_connected_players()
end

function mod.on_user_left(player)
-- cleanup connected_ysers
end

local name = "unstable_teleport"
local unstable_teleport = {
  beam_material_name = "cloud_1",
  display_name = "custom_mutator_unstable_teleport",
  beam_effect_name = "fx/leash_beam_01",
  center_sound_event = "Play_mutator_leash_center",
  icon = "mutator_icon_nurgle_storm",
  description = "description_custom_mutator_unstable_teleport",
  center_effect_name = "fx/leash_beam_center_01",
  teleport_cooldown = 2,
  warning_time = 1,

  get_player_effect_position = function (player_unit, local_player)
    local player_effect_position
    local player = Managers.player:unit_owner(player_unit)
    if player == local_player then
      local first_person_extension = ScriptUnit.extension(player_unit, "first_person_system")
      local first_person_unit = first_person_extension.first_person_unit
      player_effect_position = Unit.world_position(first_person_unit, Unit.node(first_person_unit, "root_point")) - 0.5 * Vector3.up()
    else
      local effect_node = Unit.node(player_unit, "j_spine")
      player_effect_position = Unit.world_position(player_unit, effect_node)
    end
    return player_effect_position
  end,

  is_player_alive = function(player)
    local player_health_extension = ScriptUnit.has_extension(player, "health_system")
    if ALIVE[player] and player_health_extension:is_alive() then
      return true
    end
    return false
  end,

  teleport_player = function(player_unit, to)
    local player = Managers.player:unit_owner(player_unit)
    if player.is_server then
      ScriptUnit.extension(player_unit, "locomotion_system"):teleport_to(to)
    else
      local player_unit_id = Managers.state.network:unit_game_object_id(player_unit)
      Managers.state.network.network_transmit:send_rpc(
        "rpc_teleport_unit_to",
        player.peer_id,
        player_unit_id,
        to,
        Unit.local_rotation(player_unit, 0)
      )
    end
  end,

  server_start_function = function (context, data)
    mod.connected_players = {}
    data.hero_side = Managers.state.side:get_side_from_name("heroes")
    data.has_left_safe_zone = false
    local t = Managers.time:time("game")
    data.start_teleport_at = t + data.template.teleport_cooldown
    data.teleport_at = t + data.template.teleport_cooldown + data.template.warning_time
  end,

  server_update_function = function (context, data)
    local t = Managers.time:time("game")
    local hero_side = data.hero_side
    local PLAYER_UNITS = hero_side.PLAYER_AND_BOT_UNITS

    if #PLAYER_UNITS < 2 then
      return
    end


    if data.start_teleport_at < t then
      mod.connected_players = {}
      local players = table.clone(PLAYER_UNITS)
      table.shuffle(players)
      local p1 = Math.random_range(1, #players)
      local player1 = table.remove(players, p1)
      local p2 = Math.random_range(1, #players)
      local player2 = table.remove(players, p2)
      mod.connected_players[player1] = player2
      mod.sync_connected_players()
      data.teleport_at = t + data.template.warning_time
      data.start_teleport_at = data.teleport_at + data.template.teleport_cooldown
    end

    if data.teleport_at < t then

      -- do the teleport
      for player1, player2 in pairs(mod.connected_players) do
        local position1 = POSITION_LOOKUP[player1]
        local position2 = POSITION_LOOKUP[player2]
        data.template.teleport_player(player1, position2)
        data.template.teleport_player(player2, position1)
        local player1_dialogue = ScriptUnit.extension_input(player1, "dialogue_system")

        local profile_name = ScriptUnit.extension(player1, "dialogue_system").context.player_profile
        local event_data = FrameTable.alloc_table()
        event_data.player_profile = profile_name
        event_data.source_name = profile_name
        event_data.concept = "generic_falling"
        if player1_dialogue and profile_name then
          player1_dialogue:trigger_dialogue_event("generic_falling", event_data)
        end
      end
      mod.connected_players = {}
      mod.sync_connected_players()
      data.start_teleport_at = t + data.template.teleport_cooldown
      data.teleport_at = t + data.template.teleport_cooldown + data.template.warning_time
    end
  end,

  client_start_function = function (context, data)
    local template = data.template
    local beam_effect_name = template.beam_effect_name
    local world = context.world
    local player_manager = Managers.player
    local wwise_world = Managers.world:wwise_world(world)
    local hero_side = Managers.state.side:get_side_from_name("heroes")
    data.wwise_world = wwise_world
    data.local_player = player_manager:local_player()
    data.beam_start_variable_id = World.find_particles_variable(world, beam_effect_name, "start")
    data.beam_end_variable_id = World.find_particles_variable(world, beam_effect_name, "end")
    data.beam_sound = nil
    data.beam_effects = {}
    data.hero_side = hero_side
    mod.connected_players = {}
  end,

  client_update_function = function (context, data)
    local world = context.world
    local wwise_world = data.wwise_world
    local template = data.template
    local beam_effects = data.beam_effects

    local hero_side = data.hero_side
    local PLAYER_UNITS = hero_side.PLAYER_AND_BOT_UNITS
    local is_player_alive = template.is_player_alive

    local num_alive_players = 0

    for i = 1, #PLAYER_UNITS, 1 do
      local player_unit = PLAYER_UNITS[i]
      local player_health_extension = ScriptUnit.has_extension(player_unit, "health_system")

      if ALIVE[player_unit] and player_health_extension:is_alive() then
        num_alive_players = num_alive_players + 1
      end
    end

    local center_effect_name = template.center_effect_name
    local center_sound_event = template.center_sound_event
    local beam_effect_name = template.beam_effect_name
    local beam_material_name = template.beam_material_name

    local local_player = data.local_player
    local beam_start_variable_id = data.beam_start_variable_id
    local beam_end_variable_id = data.beam_end_variable_id

    local connected_players = mod.connected_players

    if not table.is_empty(connected_players) then
      for player1, player2 in pairs(connected_players) do
        if is_player_alive(player1) and is_player_alive(player2) then

          if not beam_effects[player1] then
            local beam_effect_id = World.create_particles(world, beam_effect_name, Vector3.zero(), Quaternion.identity())
            local player1_effect_id = World.create_particles(world, center_effect_name, Vector3.zero(), Quaternion.identity())
            local player2_effect_id = World.create_particles(world, center_effect_name, Vector3.zero(), Quaternion.identity())
            beam_effects[player1] = {
              beam_effect_id = beam_effect_id,
              player1_effect_id = player1_effect_id,
              player2_effect_id = player2_effect_id,
            }
          end

          local player1_effect_id = beam_effects[player1].player1_effect_id
          local player2_effect_id = beam_effects[player1].player2_effect_id
          local player1_effect_position = template.get_player_effect_position(player1, local_player)
          local player2_effect_position = template.get_player_effect_position(player2, local_player)

          World.move_particles(world, player1_effect_id, player1_effect_position - Vector3.up() * 0.5)
          World.move_particles(world, player2_effect_id, player2_effect_position - Vector3.up() * 0.5)

          local beam_effect_id = beam_effects[player1].beam_effect_id

          World.set_particles_variable(world, beam_effect_id, beam_start_variable_id, player1_effect_position)
          World.set_particles_variable(world, beam_effect_id, beam_end_variable_id, player2_effect_position)
          World.set_particles_material_scalar(world, beam_effect_id, beam_material_name, "intensity", 5)
          World.set_particles_material_scalar(world, beam_effect_id, beam_material_name, "softness", 0)

          local player_position = POSITION_LOOKUP[local_player.player_unit]
          if data.beam_sound == nil then
            local event_id, source_id, _ = WwiseUtils.trigger_position_event(world, center_sound_event, player_position)
            data.beam_sound = {
              source_id = source_id,
              event_id = event_id
            }
          end

          WwiseWorld.set_source_position(wwise_world, data.beam_sound.source_id, player_position)
        end
      end
    else
      -- Clean up sound
      if data.beam_sound then
        local event_id = data.beam_sound.event_id

        WwiseWorld.stop_event(wwise_world, event_id)

        data.beam_sound = nil
      end

      -- Clean up beams
      for _, beam_effect in pairs(data.beam_effects) do
        World.destroy_particles(world, beam_effect.beam_effect_id)
        World.destroy_particles(world, beam_effect.player1_effect_id)
        World.destroy_particles(world, beam_effect.player2_effect_id)
      end
      data.beam_effects = {}
    end
  end,

  client_stop_function = function (context, data)
    local world = context.world
    local wwise_world = data.wwise_world

    -- Clean up sound
    if data.beam_sound then
      local event_id = data.beam_sound.event_id

      WwiseWorld.stop_event(wwise_world, event_id)

      data.beam_sound = nil
    end

    -- Clean up beams
    for _, beam_effect in pairs(data.beam_effects) do
      World.destroy_particles(world, beam_effect.beam_effect_id)
      World.destroy_particles(world, beam_effect.player1_effect_id)
      World.destroy_particles(world, beam_effect.player2_effect_id)
    end
    data.beam_effects = {}
  end
}

mod.add_mutator_template(name, unstable_teleport, 69)

mod:hook(BackendInterfaceLiveEventsPlayfab, "get_game_mode_data", function(func, ...)
  local game_mode_data = func(...)
  game_mode_data.level_key = "farmlands"
  game_mode_data.mutators = { name }
  return game_mode_data
end)
