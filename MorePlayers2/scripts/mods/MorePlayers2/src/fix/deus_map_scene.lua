-- luacheck: globals get_mod DeusMapScene
local mod = get_mod("MorePlayers2")

mod:hook(DeusMapScene, "_place_token", function(func, self, profile_index, slot, node_key)
	if slot > 4 then
		return
	end
	return func(self, profile_index, slot, node_key)
end)
