-- luacheck: globals get_mod Managers LevelSettings Unit VolumetricsFlowCallbacks
local mod = get_mod("GoToLevel")

local function is_in_hub()
	if Managers.state.game_mode then
		local level_key = Managers.state.game_mode:level_key()
		local level_settings = LevelSettings[level_key]
		return level_settings.hub_level
	end
	return false
end

mod:command("restart", "Restart the level", function()
	if is_in_hub() then
		mod:echo("You can't restart in the Keep")
	else
		if Managers.state.game_mode then
			Managers.state.game_mode:retry_level()
		end
	end
end)

mod:command("win", "Win the level", function()
	if is_in_hub() then
		mod:echo("You can't win in the Keep")
	else
		if Managers.state.game_mode then
			Managers.state.game_mode:complete_level()
		end
	end
end)

mod:command("fail", "Fail the level", function()
	if is_in_hub() then
		mod:echo("You can't fail in the Keep")
	else
		if Managers.state.game_mode then
			Managers.state.game_mode:fail_level()
		end
	end
end)

mod:hook(VolumetricsFlowCallbacks, "register_fog_volume", function(func, params)
	if (Unit.alive(params.unit)) then
		return func(params)
	end
end)

mod:hook(VolumetricsFlowCallbacks, "unregister_fog_volume", function(func, params)
	if (Unit.alive(params.unit)) then
		return func(params)
	end
end)
