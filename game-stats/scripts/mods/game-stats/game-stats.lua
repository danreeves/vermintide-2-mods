local mod = get_mod("game-stats")

local classes = {
	"bw_scholar",
	"bw_adept",
	"bw_unchained",
	"we_shade",
	"we_maidenguard",
	"we_waywatcher",
	"dr_ironbreaker",
	"dr_slayer",
	"dr_ranger",
	"wh_zealot",
	"wh_bountyhunter",
	"wh_captain",
	"es_huntsman",
	"es_knight",
	"es_mercenary"
}

local levels = {
	"dlc_bogenhafen_city",
	"skaven_stronghold",
	"ground_zero",
	"catacombs",
	"fort",
	"dlc_bogenhafen_slum",
	"military",
	"bell",
	"magnus",
	"ussingen",
	"mines",
	"warcamp",
	"nurgle",
	"prologue",
	"cemetery",
	"elven_ruins",
	"skittergate",
	"plaza",
	"forest_ambush",
	"farmlands",
}

local difficulties = {
	"normal",
	"survival_hardest",
	"hardest",
	"survival_hard",
	"survival_harder",
	"hard",
	"harder"
}

mod:command('missionstats', 'Print mission stats for class', function(class)
	mod:echo('Mission stats for ' .. class)
	local player_manager = Managers.player
	local player = player_manager:local_player()
	local stats_id = player:stats_id()
	local stats_db = player_manager:statistics_db()

	local total_count = 0
	for i,level in pairs(levels) do
		local level_count = 0
		for i,difficulty in pairs(difficulties) do
			local complete_count = stats_db:get_persistent_stat(stats_id, "completed_career_levels", class, level, difficulty) or 0
			level_count = level_count + complete_count
			total_count = total_count + complete_count
		end
		mod:echo(level .. ': ' .. level_count)
	end
	mod:echo("Total completed: " .. total_count)
end)


-- -- -- -- -- -- -- --
-- DEBUG STUFF AFTER --
-- -- -- -- -- -- -- --

-- local function debug_draw_stat(name, stat, indent_level, names_only)
-- 	local stat_type = type(stat)

-- 	if stat_type == "number" then
-- 		if not names_only then
-- 			mod:echo(string.rep(" ", indent_level * 2) .. name .. ' = ' .. stat)
-- 		end
-- 	elseif stat_type == "table" then
-- 		mod:echo(string.rep(" ", indent_level * 2) .. name)
-- 		for k, v in pairs(stat) do
-- 			debug_draw_stat(k, v, indent_level + 1, names_only)
-- 		end
-- 	end
-- end

-- StatisticsDatabase.list_stats = function (self, names_only)
-- 	for stats_id, stats in pairs(self.statistics) do
-- 		Debug.text("Stats for %s", tostring(stats_id))

-- 		for k, v in pairs(stats) do
-- 			if k == "es_knight" then
-- 				break
-- 			end
-- 			debug_draw_stat(k, v, 1, names_only)
-- 		end
-- 	end
-- end

-- mod:command('stat', 'view a stat by name', function(...)
-- 	local player_manager = Managers.player
-- 	local player = player_manager:local_player()
-- 	local stats_db = player_manager:statistics_db()
-- 	local stats_id = player:stats_id()

-- 	local stat = stats_db:get_stat(stats_id, ...)
-- 	local name = table.concat({...}, ' ')

-- 	if stat then
-- 		mod:echo(name .. ': ' .. stat)
-- 	end
-- end)

-- mod:command('stats', 'list all stats', function(names_only)
-- 	mod:echo('listing...')
-- 	local player_manager = Managers.player
-- 	local player = player_manager:local_player()
-- 	local stats_db = player_manager:statistics_db()
-- 	local stats_id = player:stats_id()
-- 	local names_only = not not names_only
-- 	stats_db:list_stats(names_only)
-- end)
