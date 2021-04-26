-- luacheck: globals get_mod Vector3 ScriptUnit ALIVE POSITION_LOOKUP Managers
-- luacheck: globals World WwiseWorld WwiseUtils Quaternion Unit BackendInterfaceLiveEventsPlayfab
-- luacheck: globals Math FrameTable table.clone table.shuffle table.is_empty
-- luacheck: globals math.lerp cjson.encode cjson.decode SharedState Network AiUtils
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

local function encode_table(tbl)
  return cjson.encode(tbl)
end

local function decode_table(str)
  return cjson.decode(str)
end

local shared_state_spec = {
  server = {
    cursed_players = {
      default_value = {},
      type = "table",
      composite_keys = {},
      encode = encode_table,
      decode = decode_table,
    }
  },
  peer = {}
}

SharedState.validate_spec(shared_state_spec)

local name = "unstable_teleport"
local shared_state_name = name .. "_shared_state"
local unstable_teleport = {
  beam_material_name = "cloud_1",
  display_name = "custom_mutator_unstable_teleport",
  beam_effect_name = "fx/leash_beam_01",
  center_sound_event = "Play_mutator_leash_loop",
  icon = "mutator_icon_nurgle_storm",
  description = "description_custom_mutator_unstable_teleport",
  center_effect_name = "fx/leash_beam_center_01",
  teleport_cooldown = 15,
  warning_time = 5,


  server_start_function = function (_, data)
    data.has_left_safe_zone = false
    data.start_teleport_at = nil
    data.teleport_at = nil
  end,

  server_players_left_safe_zone = function (_, data)
    local t = Managers.time:time("game")
    data.has_left_safe_zone = true
    data.start_teleport_at = t + data.template.teleport_cooldown
    data.teleport_at = t + data.template.teleport_cooldown + data.template.warning_time
  end,

  server_update_function = function (context, data)
    local t = Managers.time:time("game")
    local world = context.world
    local hero_side = data.hero_side
    local PLAYER_UNITS = hero_side.PLAYER_AND_BOT_UNITS
    local template = data.template
    local is_player_alive = template.is_player_alive
    local cursed_players_key = data._shared_state:get_key("cursed_players")

    if #PLAYER_UNITS < 2 then
      return
    end

    if not data.has_left_safe_zone then
      return
    end

    if data.start_teleport_at < t then
      local players = table.clone(PLAYER_UNITS)
      table.shuffle(players)
      local player1_unit = table.remove(players, 1)
      local player2_unit = table.remove(players, 1)
      local player3_unit = table.remove(players, 1)
      local player4_unit = table.remove(players, 1)
      local player1 = Managers.player:unit_owner(player1_unit)
      local player2 = Managers.player:unit_owner(player2_unit)
      local player3 = Managers.player:unit_owner(player3_unit)
      local player4 = Managers.player:unit_owner(player4_unit)

      local connections = {}
      if is_player_alive(player1_unit) and is_player_alive(player2_unit) then
        table.insert(connections, {
            player1.game_object_id,
            player2.game_object_id
          })
      end
      if is_player_alive(player3_unit) and is_player_alive(player4_unit) then
        table.insert(connections, {
            player3.game_object_id,
            player4.game_object_id
          })
      end

      data._shared_state:set_server(cursed_players_key, connections)

      data.teleport_at = t + data.template.warning_time
      data.start_teleport_at = data.teleport_at + data.template.teleport_cooldown
    end

    if data.teleport_at ~= nil and data.teleport_at < t then

      local connections = data._shared_state:get_server(cursed_players_key)

      for _, connection in ipairs(connections) do
        local player1_game_object_id = connection[1]
        local player2_game_object_id = connection[2]
        local player1 = Managers.player:player_from_game_object_id(player1_game_object_id)
        local player2 = Managers.player:player_from_game_object_id(player2_game_object_id)

        -- do the teleport
        local position1 = POSITION_LOOKUP[player1.player_unit]
        local position2 = POSITION_LOOKUP[player2.player_unit]
        data.template.teleport_player(player1.player_unit, position2)
        data.template.teleport_player(player2.player_unit, position1)

        local blackboard = {
          breed = {
            name = "undefined"
          },
          world = world
        }
        AiUtils.generic_mutator_explosion(player1.player_unit, blackboard, "generic_mutator_explosion")
        AiUtils.generic_mutator_explosion(player2.player_unit, blackboard, "generic_mutator_explosion")

        -- Trigger voice line
        -- Currently only works on Castle Drachenfels I think
        for _, player in ipairs({player1, player2}) do
          local player_dialogue = ScriptUnit.extension_input(player.player_unit, "dialogue_system")
          local event_data = FrameTable.alloc_table()
          event_data.source_name = ScriptUnit.extension(player.player_unit, "dialogue_system").context.player_profile
          player_dialogue:trigger_networked_dialogue_event("generic_falling", event_data)
        end
      end

      data._shared_state:set_server(cursed_players_key, {})
      data.start_teleport_at = t + data.template.teleport_cooldown
      data.teleport_at = t + data.template.teleport_cooldown + data.template.warning_time
    end

    local connections = data._shared_state:get_server(cursed_players_key)
    local modified_connections = {}
    for _, connection in ipairs(connections) do
      local player1_game_object_id = connection[1]
      local player2_game_object_id = connection[2]
      local player1 = Managers.player:player_from_game_object_id(player1_game_object_id)
      local player2 = Managers.player:player_from_game_object_id(player2_game_object_id)
      if is_player_alive(player1.player_unit) and is_player_alive(player2.player_unit) then
        table.insert(modified_connections, connection)
      end
    end
    if #connections ~= #modified_connections then
      data._shared_state:set_server(cursed_players_key, modified_connections)
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
    data.own_beam_sound = nil
    data.center_beam_sound = nil
    data.beam_effects = {}
    data.hero_side = hero_side

    local is_server = data.local_player.is_server
    local network_event_delegate = data.local_player.network_manager.game_mode.network_event_delegate
    local network_server = Managers.mechanism:network_handler()
    local server_peer_id = network_server.server_peer_id
    local own_peer_id = Network.peer_id()
    data._shared_state = SharedState:new(
      shared_state_name,
      shared_state_spec,
      is_server,
      network_server,
      server_peer_id,
      own_peer_id
      )
    data._shared_state:register_rpcs(network_event_delegate)

  end,

  client_update_function = function (context, data)
    local t = Managers.time:time("game")
    local world = context.world
    local wwise_world = data.wwise_world
    local template = data.template
    local beam_effects = data.beam_effects

    local is_player_alive = template.is_player_alive

    local center_effect_name = template.center_effect_name
    local center_sound_event = template.center_sound_event
    local beam_effect_name = template.beam_effect_name
    local beam_material_name = template.beam_material_name

    local local_player = data.local_player
    local beam_start_variable_id = data.beam_start_variable_id
    local beam_end_variable_id = data.beam_end_variable_id

    local cursed_players_key = data._shared_state:get_key("cursed_players")
    local connections = data._shared_state:get_server(cursed_players_key)

    if data.own_beam_sound or data.center_beam_sound and data.teleport_at ~= nil then
      local audio_system = Managers.state.entity:system("audio_system")
      local time_until = data.teleport_at - t
      local scalar = time_until / data.template.warning_time
      local audio_value = math.lerp(0.4, 1, 1 - scalar)
      audio_system:set_global_parameter("leash_distance", audio_value)
    end

    if not table.is_empty(connections) then
      if not data.teleport_at then
        data.teleport_at = t + data.template.teleport_cooldown + data.template.warning_time
      end

      for _, connection in pairs(connections) do
        local player1_game_object_id = connection[1]
        local player2_game_object_id = connection[2]
        local player1 = Managers.player:player_from_game_object_id(player1_game_object_id)
        local player2 = Managers.player:player_from_game_object_id(player2_game_object_id)

        if player1 and player2 and is_player_alive(player1.player_unit) and is_player_alive(player2.player_unit) then

          if data.center_beam_sound then
            local player1_position = POSITION_LOOKUP[player1.player_unit]
            local player2_position = POSITION_LOOKUP[player2.player_unit]
            local center_position = (player1_position + player2_position) / 2
            WwiseWorld.set_source_position(wwise_world, data.center_beam_sound.source_id, center_position)
          end

          if not beam_effects[player1] then
            local rot = Quaternion.identity()
            local v0 = Vector3.zero()
            local beam_effect_id = World.create_particles(world, beam_effect_name, v0, rot)
            local player1_effect_id = World.create_particles(world, center_effect_name, v0, rot)
            local player2_effect_id = World.create_particles(world, center_effect_name, v0, rot)
            beam_effects[player1] = {
              beam_effect_id = beam_effect_id,
              player1_effect_id = player1_effect_id,
              player2_effect_id = player2_effect_id,
            }
          end

          local player1_effect_id = beam_effects[player1].player1_effect_id
          local player2_effect_id = beam_effects[player1].player2_effect_id
          local player1_effect_position = template.get_player_effect_position(player1.player_unit, local_player)
          local player2_effect_position = template.get_player_effect_position(player2.player_unit, local_player)

          World.move_particles(world, player1_effect_id, player1_effect_position - Vector3.up() * 0.5)
          World.move_particles(world, player2_effect_id, player2_effect_position - Vector3.up() * 0.5)

          local beam_effect_id = beam_effects[player1].beam_effect_id

          World.set_particles_variable(world, beam_effect_id, beam_start_variable_id, player1_effect_position)
          World.set_particles_variable(world, beam_effect_id, beam_end_variable_id, player2_effect_position)
          World.set_particles_material_scalar(world, beam_effect_id, beam_material_name, "intensity", 5)
          World.set_particles_material_scalar(world, beam_effect_id, beam_material_name, "softness", 0)

          if data.own_beam_sound == nil then
            if player1 == local_player.player_unit or player2 == local_player.player_unit then
              local sound_id = WwiseWorld.trigger_event(wwise_world, "Play_mutator_leash_loop")
              data.own_beam_sound = sound_id
            end
          end

          if data.center_beam_sound == nil then
            local player1_position = POSITION_LOOKUP[player1.player_unit]
            local player2_position = POSITION_LOOKUP[player2.player_unit]
            local center_position = (player1_position + player2_position) / 2
            local event_id, source_id, _ = WwiseUtils.trigger_position_event(
              world,
              center_sound_event,
              center_position
              )
            data.center_beam_sound = {
              source_id = source_id,
              event_id = event_id
            }
            WwiseWorld.set_source_position(wwise_world, data.center_beam_sound.source_id, center_position)
          end
        else
          -- Clean up beam because one of the player died
          template.clean_up_beam(context, data, player1)
        end
      end
    else
      data.teleport_at = nil
      -- Clean up sounds
      template.clean_up_sounds(context, data)
      -- Clean up beams
      template.clean_up_beams(context, data)
    end
  end,

  client_stop_function = function (context, data)
    local template = data.template
    -- Clean up sounds
    template.clean_up_sounds(context, data)
    -- Clean up beams
    template.clean_up_beams(context, data)
    -- Clean up shared state
    data._shared_state:unregister_rpcs()
  end,

  clean_up_sounds = function(_, data)
    local wwise_world = data.wwise_world
    if data.own_beam_sound then
      local event_id = data.own_beam_sound
      WwiseWorld.stop_event(wwise_world, event_id)
      data.own_beam_sound = nil
    end

    if data.center_beam_sound then
      local event_id = data.center_beam_sound.event_id
      WwiseWorld.stop_event(wwise_world, event_id)
      data.center_beam_sound = nil
    end
  end,

  clean_up_beams = function(context, data)
    local world = context.world
    for _, beam_effect in pairs(data.beam_effects) do
      World.destroy_particles(world, beam_effect.beam_effect_id)
      World.destroy_particles(world, beam_effect.player1_effect_id)
      World.destroy_particles(world, beam_effect.player2_effect_id)
    end
    data.beam_effects = {}
  end,

  clean_up_beam = function(context, data, player)
    local world = context.world
    local beam_effect = data.beam_effects[player]
    World.destroy_particles(world, beam_effect.beam_effect_id)
    World.destroy_particles(world, beam_effect.player1_effect_id)
    World.destroy_particles(world, beam_effect.player2_effect_id)
    data.beam_effects[player] = nil
  end,

  get_player_effect_position = function (player_unit, local_player)
    local player_effect_position
    local player = Managers.player:unit_owner(player_unit)
    if player == local_player then
      local first_person_extension = ScriptUnit.extension(player_unit, "first_person_system")
      local first_person_unit = first_person_extension.first_person_unit
      player_effect_position = Unit.world_position(
        first_person_unit,
        Unit.node(first_person_unit, "root_point")
        ) - 0.5 * Vector3.up()
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
    if not player.remote then
      ScriptUnit.extension(player_unit, "locomotion_system"):teleport_to(to)
    else
      local player_unit_id = Managers.state.network:unit_game_object_id(player_unit)
      Managers.state.network.network_transmit:send_rpc_clients(
        "rpc_teleport_unit_to",
        player_unit_id,
        to,
        Unit.local_rotation(player_unit, 0)
        )
    end
  end,
}

mod.add_mutator_template(name, unstable_teleport)

mod:hook(BackendInterfaceLiveEventsPlayfab, "get_game_mode_data", function(func, ...)
  local game_mode_data = func(...)
  game_mode_data.level_key = "dlc_castle"
  -- game_mode_data.level_key = "farmlands"
  game_mode_data.mutators = { name }
  return game_mode_data
end)
