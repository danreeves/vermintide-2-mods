-- luacheck: globals get_mod StartGameWindowLobbyBrowser
local mod = get_mod("MorePlayers2")
mod:hook_safe(StartGameWindowLobbyBrowser, "_handle_lobby_data", function(self, _, lobby_data)
	local num_players = lobby_data.num_players
	local max_players = lobby_data.btmp_max_players or "4"

	if num_players and max_players then
		local info_box_widgets_lobbies = self._lobby_info_box_lobbies_widgets_by_name
		local info_box_widgets_servers = self._lobby_info_box_servers_widgets_by_name

		local num_players_text = string.format("%s/%s", num_players, max_players)
		info_box_widgets_lobbies.info_frame_players_text.content.text = num_players_text
		info_box_widgets_servers.info_frame_players_text.content.text = num_players_text
	end
end)
