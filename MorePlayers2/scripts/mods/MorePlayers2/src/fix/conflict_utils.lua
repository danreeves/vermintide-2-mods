-- luacheck: globals get_mod ConflictUtils
local mod = get_mod("MorePlayers2")

-- These could be implemented correctly but it doesn't make a noticable
-- difference when there's a lot of players.

mod:hook_origin(ConflictUtils, "cluster_positions", function(positions)
	if not positions then
		return {}, {}, {}
	end
	if #positions < 1 then
		return {}, {}, {}
	end
	return { positions[1] }, { 1 }, { 1 }
end)

mod:hook_origin(ConflictUtils, "cluster_weight_and_loneliness", function()
	return 1, 1, 100
end)
