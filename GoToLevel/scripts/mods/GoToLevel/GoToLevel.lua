-- luacheck: globals get_mod Managers LevelSettings Unit VolumetricsFlowCallbacks
-- luacheck: globals string.starts_with Localize
local mod = get_mod("GoToLevel")
local fzy = mod:dofile("scripts/mods/GoToLevel/fzy")

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

mod:command("load", "Load a level with fuzzy matching", function(input)
	if not input then
		mod:echo("Pass a search string")
		return
	end

	input = input:lower()
	local names = {}
	local local_to_key = {}
	for key, data in pairs(LevelSettings) do
		if data.mechanism == "adventure" and
			not data.hub_level and
			data.game_mode ~= "deus" and
			not string.starts_with(key, "dlc_scorpion_") and
			key ~= "prologue" then

			local name = Localize(data.display_name):lower()
			if not string.starts_with(name, "<") then
				table.insert(names, name)
				local_to_key[name] = key
			end
		end
	end

	local tmp
	local min = 100
	local result = ""

	for _, p in pairs(names) do
		if fzy.has_match(input, p) then
			tmp = fzy.score(input, p, false)
			if tmp < min then
				min, result = tmp, p
			end
		end
	end

	if result ~= "" then
		local key = local_to_key[result]
		local level = LevelSettings[key]
		mod:echo("Loading: " .. Localize(level.display_name))
		Managers.state.game_mode:start_specific_level(key)
	else
		mod:echo("No matches for: " .. input)
	end
end)

if not mod:get("go_to_level_enabled") then
	mod:command_disable("load")
end

function mod.on_setting_changed()
	if mod:get("go_to_level_enabled") then
		mod:command_enable("load")
	end
	if not mod:get("go_to_level_enabled") then
		mod:command_disable("load")
	end
end

--
-- Fixes
--
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
