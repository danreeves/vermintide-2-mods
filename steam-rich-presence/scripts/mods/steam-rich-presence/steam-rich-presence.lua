local mod = get_mod("steam-rich-presence")

local function lobby_level(lobby_data)
  local lvl = lobby_data.selected_level_key or lobby_data.level_key
  local lvl_setting = lvl and LevelSettings[lvl]
  local lvl_display_name = lvl_setting and lvl_setting.display_name
  local lvl_text = lvl_display_name and Localize(lvl_display_name)
  return lvl_text or "No Level"
end

local function lobby_difficulty(lobby_data)
  local dw_enabled, ons_enabled = false, false
  local dwons_qol = get_mod("is-dwons-on")
  if dwons_qol then
    dw_enabled, ons_enabled = dwons_qol.get_status()
  end

  if dw_enabled or ons_enabled then
    return string.format(
      "%s%s%s",
      dw_enabled and "Deathwish" or "",
      dw_enabled and ons_enabled and " " or "",
      ons_enabled and "Onslaught" or ""
    )
  end

  local diff = lobby_data.difficulty
  local diff_setting = diff and DifficultySettings[diff]
  local diff_display_name = diff_setting and diff_setting.display_name
  local diff_text = diff_display_name and Localize(diff_display_name)
  return diff_text or "No Difficulty"
end

local function lobby_act(lobby_data)
  local act_key = lobby_data.act_key
  return act_key and Localize(act_key .. "_ls")
end

local function lobby_info_string(lobby_data, num_players)
  return string.format(
    "(%s/4) %s | %s | %s %s %s",
    num_players,
    lobby_data.eac_authorized == "true" and "Official Realm" or "Modded Realm",
    lobby_difficulty(lobby_data),
    lobby_level(lobby_data),
    lobby_data.quick_game == "true" and "| Quickplay" or "",
    lobby_data.twitch_enabled == "true" and "| Twitch Mode" or ""
  )
end


function mod.update_presence()
  if not Managers.state then
    return
  end

  if not Managers.state.network then
    return
  end

  local lobby = Managers.state.network:lobby()
  if not lobby then
    return
  end

  local lobby_data = lobby:get_stored_lobby_data()
  if not lobby_data then
    return
  end

  local num_players = lobby_data.num_players or Managers.player:num_human_players()

  local status = lobby_info_string(lobby_data, num_players)
  Presence.set_presence("status", status)
  Presence.set_presence("steam_display", status)
  Presence.set_presence("steam_player_group", lobby:id())
  Presence.set_presence("steam_player_group_size", num_players)
end

function mod.on_game_state_changed()
  mod.update_presence()
end

mod:hook_safe(PlayerManager, "add_player", function()
  mod.update_presence()
end)

mod:hook_safe(PlayerManager, "add_remote_player", function()
  mod.update_presence()
end)

mod:hook_safe(PlayerManager, "remove_player", function()
  mod.update_presence()
end)
