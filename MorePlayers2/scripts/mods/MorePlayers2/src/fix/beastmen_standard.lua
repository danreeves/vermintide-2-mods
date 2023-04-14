-- luacheck: globals get_mod BeastmenStandardExtension
local mod = get_mod("MorePlayers2")

mod:hook_safe(BeastmenStandardExtension, "init", function(self)
	if self.is_server then
		local t = Managers.time:time("game")
		for i = 5, mod.MAX_PLAYERS, 1 do
			self.player_astar_data[i] = {
				next_astar_check_t = t + self.astar_check_frequency,
			}
		end
	end
end)
