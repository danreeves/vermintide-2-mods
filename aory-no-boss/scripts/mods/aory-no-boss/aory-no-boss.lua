local mod = get_mod("aory-no-boss")

mod:hook(TerrorEventMixer, "start_event", function(func, name, data)

    -- if data.event_kind == "event_boss" or data.event_kind == "event_patrol" then
    -- mod:echo('%s', name)
    -- for k,v in pairs(data) do
    -- mod:echo(' - %s: %s', k, v)
    -- end
    -- mod:echo('')
    -- end

    local current_level = Managers.state.game_mode and Managers.state.game_mode:level_key()
    if current_level == "military" and data.event_kind == "event_boss" and data.map_section == 2 then
      mod:echo("OMEGALULEatingAnEggplant")
      return
    end

    func(name, data)
end)
