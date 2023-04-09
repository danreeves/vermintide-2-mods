local mod = get_mod("netstat")
local definitions = mod:dofile("scripts/mods/netstat/netstat_definitions")
local NetStatUI = class()

local fake_input_service = {
	get = function()
		return
	end,
	has = function()
		return
	end,
}

local function avg(list)
	local sum = 0
	for _, x in ipairs(list) do
		sum = sum + x
	end
	return sum / #list
end

function NetStatUI:init()
	self.ping_history = {}
	self.next_update = 0
	self.update_interval = 1.0
	self.history_kept = 30

	local world = Managers.world:world("top_ingame_view")
	self.ui_renderer = UIRenderer.create(world, "material", "materials/fonts/gw_fonts")
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self.ui_widget = UIWidget.init(definitions.widget_definition)
end

function NetStatUI:update()
	local t = Managers.time:time("game")
	if not t or self.next_update >= t then
		return
	end

	self.next_update = t + self.update_interval

	local game_session = Managers.state.network:game()
	local local_player = Managers.player:local_player()
	local players = Managers.player:players()
	local ping_history = self.ping_history
	local widget = self.ui_widget
	local other_players = {}

	-- Reset widget data
	for i = 4, 1 do
		widget.content["show_player_" .. i] = false
		widget.content["player_name_" .. i] = ""
		widget.content["current_ping_text_" .. i] = ""
		widget.content["min_ping_text_" .. i] = ""
		widget.content["max_ping_text_" .. i] = ""
		widget.content["avg_ping_text_" .. i] = ""
	end

	-- Return early if there is no game session yet
	-- e.g. in a loading screen
	if not game_session then
		return
	end

	-- Get the ping for each player and store it
	for _, player in pairs(players) do
		local is_bot_player = player.bot_player or not player:is_player_controlled()
		if not is_bot_player then
			-- Keep track of other players so we can loop over them to
			-- update widget contents later
			if player.game_object_id ~= local_player.game_object_id then
				table.insert(other_players, player)
			end

			local game_object_id = player.game_object_id
			local ping = GameSession.game_object_field(game_session, game_object_id, "ping")
			local player_ping_history = ping_history[game_object_id] or {}

			--[[ DEBUG: DELETE ME ]]
			--
			--local ping = math.random(50, 90)

			table.insert(player_ping_history, 1, ping)
			table.remove(player_ping_history, self.history_kept + 1)
			ping_history[game_object_id] = player_ping_history
		end
	end

	-- Set the UI contents
	-- Local player is always first
	widget.content.show_player_1 = not local_player.is_server
	widget.content.current_ping_text_1 = string.format("%i", ping_history[local_player.game_object_id][1])
	widget.content.min_ping_text_1 = string.format("%i", math.min(unpack(ping_history[local_player.game_object_id])))
	widget.content.max_ping_text_1 = string.format("%i", math.max(unpack(ping_history[local_player.game_object_id])))
	widget.content.avg_ping_text_1 = string.format("%i", avg(ping_history[local_player.game_object_id]))

	-- Set other player contents
	for i, player in ipairs(other_players) do
		if i > 3 then
			-- I don't care about supporting More Characters right now
			-- I just don't want it to break stuff
			break
		end
		widget.content["show_player_" .. i + 1] = ping_history[player.game_object_id][1] ~= 0
		widget.content["player_name_" .. i + 1] = player:name()
		widget.content["current_ping_text_" .. i + 1] = string.format("%i", ping_history[player.game_object_id][1])
		widget.content["min_ping_text_" .. i + 1] = string.format(
			"%i",
			math.min(unpack(ping_history[player.game_object_id]))
		)
		widget.content["max_ping_text_" .. i + 1] = string.format(
			"%i",
			math.max(unpack(ping_history[player.game_object_id]))
		)
		widget.content["avg_ping_text_" .. i + 1] = string.format("%i", avg(ping_history[player.game_object_id]))
	end
end

function NetStatUI:draw(dt)
	local ui_renderer = self.ui_renderer
	local ui_scenegraph = self.ui_scenegraph
	local ui_widget = self.ui_widget

	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, fake_input_service, dt)
	UIRenderer.draw_widget(ui_renderer, ui_widget)
	UIRenderer.end_pass(ui_renderer)
end

mod.update = function(dt)
	if not mod.netstatui then
		mod.netstatui = NetStatUI:new()
	end

	mod.netstatui:update()
	mod.netstatui:draw(dt)
end
