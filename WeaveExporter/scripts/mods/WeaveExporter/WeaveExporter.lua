-- luacheck: globals get_mod Localize DifficultySettings WeaveSettings WeaveManager WindSettings
local mod = get_mod("WeaveExporter")

local app_data = os.getenv("APPDATA")
local desktop = app_data:gsub("\\AppData\\Roaming", "\\Desktop\\")
local column_order = {
	"weave",
	"difficulty",
	"wind",
	"strength",
	"level",
	"objective",
	"arena_objective",
	"enemy_damage",
	"diminishing_damage",
	"extra_mutator_setting_1",
	"extra_mutator_setting_2",
	"extra_mutator_setting_3",
	"extra_mutator_setting_4",
	"extra_mutator_setting_5",
	"extra_mutator_setting_6",
	"extra_mutator_setting_7",
	"extra_mutator_setting_8",
	"extra_mutator_setting_9",
	"extra_mutator_setting_10",
}

local function gsc(weave, key)
	local active_weave = {
		_active_weave_name = weave.name,
	}
	return (1 + WeaveManager.get_scaling_value(active_weave, key)) * 100
end

local weave_extra_data = {
	power_level = "power_level",
	radius = "radius",
	thorns_damage = "thorns_damage",
	thorns_life_time = "thorns_life_time",
	thorns_buff_duration = "thorns_buff_duration",
	power_level_player = "power_level_player",
	power_level_ai = "power_level_ai",
	spawn_rate = "spawn_rate",
	buff_time_player = "buff_time_player",
	buff_time_enemy = "buff_time_enemy",
	light_radius = "light_radius",
	damage_taken = "damage_taken",
	respawn_rate = "respawn_rate",
	timed_explosion_extension_settings = {
		"time_to_explode",
		"follow_time",
	},
	spirit_settings = {
		"damage",
		"wait_time",
		"chase_speed",
		"chase_time",
	},
	curse_settings = {
		"value",
		"curse_rate",
	},
}

local function write(filename, contents)
	mod:echo("Writing to " .. filename)
	local file = io.open(filename, "w+")
	file:write(contents)
	file:close()
end

local function to_csv(data)
	local str = ""
	for i = 1, #data, 1 do
		local row = data[i]
		for j = 1, #column_order, 1 do
			local col = column_order[j]
			local val = row[col]
			if val then
				str = str .. val .. ", "
			end
		end
		str = str .. "\n"
	end
	return str
end

mod:command("export_weaves", "Export weave data", function(custom_path)
	local data = {}
	for _, weave in pairs(WeaveSettings.templates_ordered) do
		local row = {}
		row.weave = weave.tier
		row.difficulty = Localize(DifficultySettings[weave.difficulty_key].display_name)
		row.wind = weave.wind
		row.strength = weave.wind_strength
		row.level = Localize(weave.objectives[1].base_level_id)
		row.objective = Localize(weave.objectives[1].display_name)
		row.arena_objective = Localize(weave.objectives[2].display_name)
		row.enemy_damage = string.format("%d%%", gsc(weave, "enemy_damage"))
		row.diminishing_damage = string.format("%d%%", gsc(weave, "diminishing_damage"))

		local extra_index = 0
		local wind = WindSettings[weave.wind]
		local difficulty_rank = DifficultySettings[weave.difficulty_key].rank
		for index, key in pairs(weave_extra_data) do
			if type(key) == "table" then
				for j = 1, #key, 1 do
					local subkey = key[j]
					local settings = wind[index]
					local val
					if settings then
						val = settings[subkey][weave.difficulty_key]
					end
					if val then
						if type(val) == "table" then
							val = val[difficulty_rank]
						end
						extra_index = extra_index + 1
						row["extra_mutator_setting_" .. extra_index] = subkey .. "=" .. val
					end
				end
			end

			if wind[key] then
				local val = wind[key][weave.difficulty_key]
				if val then
					if type(val) == "table" then
						val = val[difficulty_rank]
					end
					extra_index = extra_index + 1
					row["extra_mutator_setting_" .. extra_index] = key .. "=" .. val
				end
			end
		end
		table.insert(data, row)
	end

	local path = custom_path and custom_path or desktop .. "weave_data.csv"
	write(path, to_csv(data))
end)
