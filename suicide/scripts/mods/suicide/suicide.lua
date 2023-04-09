local mod = get_mod("suicide")

-- Are we currently loaded at the inn?
-- from Zaphio
local function is_at_inn()
	local game_mode = Managers.state.game_mode
	if not game_mode then
		return nil
	end
	return game_mode:game_mode_key() == "inn"
end

mod:command("die", "Kill yourself", function()
	if is_at_inn() then
		mod:echo("You cannot die in the keep")
		return
	end

	local player_unit = Managers.player:local_player().player_unit
	local death_system = Managers.state.entity:system("death_system")
	death_system:kill_unit(player_unit, {})
	Managers.chat:send_chat_message(1, 1, "Guess I'll die-die...", false, nil, false)
end)
