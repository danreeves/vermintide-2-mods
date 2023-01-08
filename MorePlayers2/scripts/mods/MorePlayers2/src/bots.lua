-- luacheck: globals get_mod script_data GameModeAdventure GameModeDeus
local mod = get_mod("MorePlayers2")

script_data.cap_num_bots = mod:get("num_bots")

local profiles = {
	{ 1, 1 },
	{ 1, 2 },
	{ 1, 3 },
	{ 1, 4 },

	{ 2, 1 },
	{ 2, 2 },
	{ 2, 3 },
	-- { 2, 4 },  -- sienna

	{ 3, 1 },
	{ 3, 2 },
	{ 3, 3 },
	{ 3, 4 },

	{ 4, 1 },
	{ 4, 2 },
	{ 4, 3 },
	{ 4, 4 },

	{ 5, 1 },
	{ 5, 2 },
	{ 5, 3 },
	{ 5, 4 },
}

local function random_bot()
	local profile = table.random(profiles)
	return profile[1], profile[2]
end

mod:hook(GameModeAdventure, "_get_first_available_bot_profile", random_bot)

mod:hook(GameModeDeus, "_get_first_available_bot_profile", random_bot)
