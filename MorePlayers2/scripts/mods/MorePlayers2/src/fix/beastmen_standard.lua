-- luacheck: globals get_mod BeastmenStandardExtension
local mod = get_mod("MorePlayers2")

mod:hook(BeastmenStandardExtension, "init", function(func, self, ...)
	func(self, ...)
	if self.is_server then
		local astar_data = self.player_astar_data[1]
		for i = 1, mod.MAX_PLAYERS, 1 do
			self.player_astar_data[i] = astar_data
		end
	end
end)
