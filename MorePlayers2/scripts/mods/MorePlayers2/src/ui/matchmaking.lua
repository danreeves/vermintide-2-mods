-- luacheck: globals get_mod MatchmakingUI MatchmakingStateHostGame
local mod = get_mod("MorePlayers2")

-- Not very important UI to improve. It doesn't crash but you can't tell
-- who hasn't voted unless they are in the four visible.

-- For all of these functions we just need to stop them indexing greater than
-- four players so they don't crash.
local function matchmakinguihooks(func, self, index, ...)
	if index <= 4 then
		func(self, index, ...)
	end
end

mod:hook(MatchmakingUI, "large_window_set_player_portrait", matchmakinguihooks)
mod:hook(MatchmakingUI, "large_window_set_player_connecting", matchmakinguihooks)
mod:hook(MatchmakingUI, "_set_player_is_voting", matchmakinguihooks)
mod:hook(MatchmakingUI, "_set_player_voted_yes", matchmakinguihooks)

-- Maybe these hooks will fix a random crash
mod:hook(MatchmakingUI, "_get_portrait_index", function(func, ...)
	local ret = func(...)
	if ret == nil then
		return 1
	end
end)

-- Maybe these hooks will fix a random crash
mod:hook(MatchmakingUI, "_get_first_free_portrait_index", function(func, ...)
	local ret = func(...)
	if ret == nil then
		return 1
	end
end)

mod:hook_origin(MatchmakingUI, "_get_party_slot_index_by_peer_id", function(self, peer_id)
	for i = 1, self._max_number_of_players, 1 do
		local widget_name = "party_slot_" .. i
		local widget = self:_get_detail_widget(widget_name)

		-- MODIFIED. Check we have a widget before indexing it
		if not widget then
			return
		end

		local content = widget.content

		if content.peer_id == peer_id then
			return i
		end
	end
end)

mod:hook_safe(MatchmakingStateHostGame, "_start_hosting_game", function()
	mod.update_lobby_data()
end)
