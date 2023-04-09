-- luacheck: globals get_mod SteamLobbyBrowser
local mod = get_mod("MorePlayers2")

mod:hook_origin(SteamLobbyBrowser, "add_filter", function(func, lobby_browser, key, value, steam_comparison)
	-- Check key and value exist before calling the function
	-- I can't see inside SteamLobbyBrowser but it has crashed when someone
	-- joined during the end game screen because value was nil instead of
	-- a number. I dunno.
	if key and value then
		func(lobby_browser, key, value, steam_comparison)
	end
end)
