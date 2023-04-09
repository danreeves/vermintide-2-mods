-- luacheck: globals get_mod GameSession
local mod = get_mod("MorePlayers2")

mod:hook(GameSession, "game_object_field", function(func, self, go_id, key, ...)
	-- Return early if game object doesn't exist
	local go_exists = GameSession.game_object_exists(self, go_id)

	if not go_exists then
		if key == "current_health" then
			return 0
		end

		if key == "temporary_health" then
			return 0
		end

		if key == "current_temporary_health" then
			return 0
		end

		if key == "max_health" then
			return 0
		end

		return
	end

	local value = func(self, go_id, key, ...)
	if key == "local_player_id" then
		if value == 0 then
			mod:debug("[BTMP] local_player_id was 0. setting to 8")
			value = 8
		end
	end
	return value
end)
