local mod = get_mod("MorePlayers2")

PlayerManager.MAX_PLAYERS = mod.MAX_PLAYERS
MatchmakingSettings.MAX_NUMBER_OF_PLAYERS = mod.MAX_PLAYERS
GameSettingsDevelopment.lobby_max_members = mod.MAX_PLAYERS

local function get_network_options()
	local network_options = {
		config_file_name = "content/MorePlayers2/global", -- MODIFIED
		ip_address = Network.default_network_address(),
		lobby_port = GameSettingsDevelopment.network_port,
		map = "None",
		max_members = mod.MAX_PLAYERS,
		project_hash = "bulldozer",
		query_port = script_data.query_port or script_data.settings.query_port,
		server_port = script_data.server_port or script_data.settings.server_port or 27015,
		steam_port = script_data.steam_port or script_data.settings.steam_port,
	}
	return network_options
end

mod:hook_origin(LobbyManager, "setup_network_options", function(self, increment_lobby_port)
	local network_options = get_network_options()
	local lobby_port = script_data.server_port or script_data.settings.server_port or network_options.lobby_port
	lobby_port = lobby_port + self._lobby_port_increment
	if increment_lobby_port then
		self._lobby_port_increment = self._lobby_port_increment + 1
	end
	network_options.lobby_port = lobby_port
	self._network_options = network_options
end)

mod:hook_origin(GameMechanismManager, "max_members", function()
	return mod.MAX_PLAYERS
end)
mod:hook_origin(AdventureMechanism, "profile_available", function()
	return true
end)
mod:hook_origin(AdventureMechanism, "profile_available_for_peer", function()
	return true
end)
mod:hook_origin(ProfileSynchronizer, "is_profile_in_use", function()
	return false
end)
mod:hook_origin(ProfileSynchronizer, "is_free_in_lobby", function()
	return true
end)
mod:hook_origin(ProfileSynchronizer, "try_reserve_profile_for_peer", function()
	return true
end)

mod:hook(PartyManager, "get_party", function(func, self, num)
	local p = self._parties[num]
	if p then
		p.num_slots = mod.MAX_PLAYERS
	end
	return func(self, num)
end)
