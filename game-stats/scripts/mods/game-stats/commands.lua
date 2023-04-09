local mod = get_mod("game-stats")

local stats_for_class = mod.stats_for_class
local levels = mod.levels
local difficulties = mod.difficulties
local toggle_window = mod.toggle_window

mod:command("completion_by_difficulty_for", "Print mission stats for class", function(class)
	local total_wins, difficulty_total_wins = stats_for_class(class)
	mod:echo("Level completion for " .. Localize(class) .. ":")
	for i, difficulty in pairs(difficulties) do
		local difficulty_settings = DifficultySettings[difficulty]
		local display_name = difficulty_settings.display_name
		mod:echo(Localize(display_name) .. ": " .. difficulty_total_wins[difficulty])
	end
	mod:echo("Total: " .. total_wins)
end)

mod:command("completion_by_level_for", "Print mission stats for class", function(class)
	local _1, _2, level_total_wins = stats_for_class(class)
	mod:echo("Level completion for " .. Localize(class) .. ":")
	for i, level in pairs(levels) do
		local level_settings = LevelSettings[level]
		local display_name = level_settings.display_name
		mod:echo(Localize(display_name) .. ": " .. level_total_wins[level])
	end
end)

mod:command("missionstats", "Open the Mission Stats window", function()
	toggle_window()
end)

return
