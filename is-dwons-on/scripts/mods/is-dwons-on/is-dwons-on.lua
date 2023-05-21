local mod = get_mod("is-dwons-on")
local definitions = mod:dofile("scripts/mods/is-dwons-on/is-dwons-on_definitions")

-- Reload the UI when mods are reloaded or a setting is changed.
local DO_RELOAD = true
Boot._dwons_booted = false

local mod_names = {
	{ "Deathwish", "catas", "catas" },
	{ "Onslaught", "Onslaught", "Onslaught" },
	{ "Onslaught Plus", "OnslaughtPlus", "OnslaughtPlus" },
	{ "Onslaught Squared", "OnslaughtPlus", "OnslaughtSquared" },
	{ "Enhanced Difficulty", "OnslaughtPlus", "EnhancedDifficulty" },
	{ "More Specials", "OnslaughtPlus", "MoreSpecials" },
	{ "Beastmen Rework", "OnslaughtPlus", "BeastmenRework" },
	{ "Spicy Onslaught", "SpicyOnslaught", "SpicyOnslaught" },
	{ "Dutch Spice", "DutchSpice", "DutchSpice" },
	{ "Dutch Spice Tourney", "DutchSpiceTourney", "DutchSpiceTourney" },
}

function mod.register_mutator(label, mod_name, mutator_name)
	local found = false
	for _, mutator_info in ipairs(mod_names) do
		if mutator_info[2] == mod_name and mutator_info[3] == mutator_name then
			found = true
			mutator_info = { label, mod_name, mutator_name }
		end
	end

	if not found then
		table.insert(mod_names, { label, mod_name, mutator_name })
	end
end

function mod.on_setting_changed()
	DO_RELOAD = true
end

function mod.is_mod_installed(mod_name)
	if get_mod(mod_name) then
		return true
	end
	return false
end

function mod.is_mutator_enabled(mod_name, mutator_name)
	if not Managers.player.is_server and mod.rpc_state.host_synced then
		return mod.rpc_state[mod_name .. mutator_name]
	end

	local mutator_mod = get_mod(mod_name)
	if not mutator_mod then
		return false
	end
	local mutator = mutator_mod:persistent_table(mutator_name)
	if not mutator then
		return false
	end
	return mutator.active and true or false
end

function mod.enable_mutator(mod_name, mutator_name)
	local mutator_mod = get_mod(mod_name)
	if mutator_mod then
		local mutator = mutator_mod:persistent_table(mutator_name)
		if mutator then
			mutator.start()
		end
	end
end

function mod.toggle_mutator(mod_name, mutator_name)
	local mutator_mod = get_mod(mod_name)
	if mutator_mod then
		local mutator = mutator_mod:persistent_table(mutator_name)
		if mutator then
			mutator.toggle()
		end
	end
end

function mod.disable_mutator(mod_name, mutator_name)
	local mutator_mod = get_mod(mod_name)
	if mutator_mod then
		local mutator = mutator_mod:persistent_table(mutator_name)
		if mutator then
			mutator.stop()
		end
	end
end

function mod.get_status()
	local dw_enabled = mod.is_mutator_enabled("catas", "catas")
	local ons_enabled = mod.is_mutator_enabled("Onslaught", "Onslaught")
	return dw_enabled, ons_enabled
end

function mod.is_at_inn()
	local game_mode = Managers.state.game_mode
	if not game_mode then
		return nil
	end
	return game_mode:game_mode_key() == "inn"
end

function mod.is_host_or_host_synced()
	return Managers.player.is_server or mod.rpc_state.host_synced
end

local IsDwonsOn = mod:persistent_table("IsDwonsOn_class", class())

function IsDwonsOn:init(ingame_ui_context)
	self.ui_renderer = ingame_ui_context.ui_renderer
	self:create_ui()
end

function IsDwonsOn:create_ui()
	local scenegraph_definition = definitions.create_scenegraph_definition(mod:get("x"), mod:get("y"))
	self.ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
	self.ui_widgets = {}
	for i, _ in ipairs(mod_names) do
		local widget_definition = definitions.create_widget_definition()
		self.ui_widgets[i] = UIWidget.init(widget_definition)
	end
	self:update_style()
	DO_RELOAD = false
end

function IsDwonsOn:update_style()
	local font_size = mod:get("font_size")
	for _, widget in ipairs(self.ui_widgets) do
		widget.style.text.font_size = font_size
	end

	if mod:get("align_vertically") then
		local horizontal_alignment = mod:get("horizontal_alignment")
		local row = 1
		for i, mutator in ipairs(mod_names) do
			local is_installed = mod.is_mod_installed(mutator[2])
			local widget = self.ui_widgets[i]
			if is_installed then
				widget.style.text.offset[2] = -(row * font_size)
				widget.style.text.horizontal_alignment = horizontal_alignment
				-- widget.style.text.vertical_alignment = "center"
				row = row + 1
			end
		end
	else
		local offset = 0
		for i, mutator in ipairs(mod_names) do
			local is_installed = mod.is_mod_installed(mutator[2])
			local widget = self.ui_widgets[i]
			if is_installed then
				local width, height = UIRenderer.text_size(
					self.ui_renderer,
					widget.content.text,
					"materials/fonts/gw_body",
					font_size
				)
				widget.style.text.offset[1] = offset
				widget.style.text.horizontal_alignment = "left"
				widget.style.text.vertical_alignment = "center"
				offset = offset + width + 10
			end
		end
	end
end

function IsDwonsOn:update()
	if DO_RELOAD then
		self:create_ui()
	end

	self:update_style()

	local widgets = self.ui_widgets

	for i, mutator in ipairs(mod_names) do
		local widget = widgets[i]
		local label = mutator[1]
		local mod_name = mutator[2]
		local mutator_name = mutator[3]
		local is_installed = mod.is_mod_installed(mod_name)
		local is_active = mod.is_mutator_enabled(mod_name, mutator_name)

		if is_installed then
			widget.content.text = string.format("%s: %s", label, is_active)
		else
			widget.content.text = ""
		end
	end
end

local fake_input_service = {
	get = function()
		return
	end,
	has = function()
		return
	end,
}
function IsDwonsOn:draw(dt)
	local ui_renderer = self.ui_renderer
	local ui_scenegraph = self.ui_scenegraph
	local widgets = self.ui_widgets

	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, fake_input_service, dt)
	for _, widget in ipairs(widgets) do
		UIRenderer.draw_widget(ui_renderer, widget)
	end
	UIRenderer.end_pass(ui_renderer)
end

-- INIT
mod._mod_ui = IsDwonsOn:new(Managers.ui._ingame_ui_context)

-- UPDATE
mod.update = function(dt, _t)
	if not mod._mod_ui then
		return
	end
	mod._mod_ui:update()
	mod._mod_ui:draw(dt)
end

-- COMMANDS
mod.dwons_active = false
function mod.toggle()
	local deathwish_mod = get_mod("catas")
	local onslaught_mod = get_mod("Onslaught")
	mod.dwons_active = not mod.dwons_active

	if not deathwish_mod then
		mod:chat_broadcast("SKIPPING. Deathwish is not installed.")
	else
		local deathwish = deathwish_mod:persistent_table("catas")
		if deathwish.active ~= mod.dwons_active then
			deathwish.toggle()
		else
			mod:chat_broadcast(string.format("Deathwish already %s.", mod.dwons_active and "ENABLED" or "DISABLED"))
		end
	end

	if not onslaught_mod then
		mod:chat_broadcast("SKIPPING. Onslaught is not installed.")
	else
		local onslaught = onslaught_mod:persistent_table("Onslaught")
		if onslaught.active ~= mod.dwons_active then
			onslaught.toggle()
		else
			mod:chat_broadcast(string.format("Onslaught already %s.", mod.dwons_active and "ENABLED" or "DISABLED"))
		end
	end

	mod.sync_state()
end
mod:command("dwons", "Toggle Deathwish & Onslaught. Must be host and in the keep.", mod.toggle)

mod:command("turn_all_off", "Turn off all mods DwOns QoL mod knows about", function()
	for _, mutator_info in ipairs(mod_names) do
		local mod_name = mutator_info[2]
		local mutator_name = mutator_info[3]
		local mutator_mod = get_mod(mod_name)
		if mutator_mod then
			local mutator = mutator_mod:persistent_table(mutator_name)
			if mutator then
				mutator.stop()
			end
		end
	end
end)

-- RPC State
mod.rpc_state = {
	host_synced = false,
}

for _, mutator in ipairs(mod_names) do
	mod.rpc_state[mutator[2] .. mutator[3]] = false
end

mod:network_register("dwons_state_sync", function(_sender, data)
	mod.rpc_state.host_synced = true
	for key, value in pairs(data) do
		mod.rpc_state[key] = value
	end
end)

function mod.on_user_joined()
	mod.sync_state()
end

function mod.on_game_state_changed(status, state)
	if status == "enter" and state == "StateIngame" then
		if Managers.player.is_server then
			mod.rpc_state = {
				host_synced = false,
			}

			for _, mutator in ipairs(mod_names) do
				mod.rpc_state[mutator[2] .. mutator[3]] = false
			end

			if mod:get("enable_on_boot") and not Boot._dwons_booted then
				mod.toggle()
				mod.dwons_active = true
				Boot._dwons_booted = true
			end

			mod.sync_state()
		end
	end
end

function mod.sync_state()
	local data = {}
	for _, mutator in ipairs(mod_names) do
		local mod_name = mutator[2]
		local mutator_name = mutator[3]
		local is_active = mod.is_mutator_enabled(mod_name, mutator_name)
		data[mod_name .. mutator_name] = is_active
	end
	mod:network_send("dwons_state_sync", "others", data)
end

local function hook_mods()
	for _, mutator_info in ipairs(mod_names) do
		local mod_name = mutator_info[2]
		local mutator_name = mutator_info[3]
		local mutator_mod = get_mod(mod_name)
		if mutator_mod then
			local mutator = mutator_mod:persistent_table(mutator_name)
			if mutator then
				mod:hook_safe(mutator, "start", mod.sync_state)
				mod:hook_safe(mutator, "stop", mod.sync_state)
			end
		end
	end
end

local function unhook_mods()
	for _, mutator_info in ipairs(mod_names) do
		local mod_name = mutator_info[2]
		local mutator_name = mutator_info[3]
		local mutator_mod = get_mod(mod_name)
		if mutator_mod then
			local mutator = mutator_mod:persistent_table(mutator_name)
			if mutator then
				mod:hook_disable(mutator, "start")
				mod:hook_disable(mutator, "stop")
			end
		end
	end
end

function mod.on_all_mods_loaded()
	hook_mods()
end

function mod.on_unload()
	unhook_mods()
end

function mod.is_spawn_tweaks_customized()
	local spawn_tweaks = get_mod("SpawnTweaks")

	if not spawn_tweaks or not spawn_tweaks:is_enabled() then
		return {}
	end

	local are_hordes_customized = spawn_tweaks:get(spawn_tweaks.SETTING_NAMES.HORDES) ~= spawn_tweaks.HORDES.DEFAULT
	local are_bosses_customized = spawn_tweaks:get(spawn_tweaks.SETTING_NAMES.BOSSES) ~= spawn_tweaks.BOSSES.DEFAULT
	local are_ambients_customized = spawn_tweaks:get(spawn_tweaks.SETTING_NAMES.AMBIENTS)
		~= spawn_tweaks.AMBIENTS.DEFAULT
	local are_specials_customized = spawn_tweaks:get(spawn_tweaks.SETTING_NAMES.SPECIALS)
		~= spawn_tweaks.SPECIALS.DEFAULT

	return {
		Hordes = are_hordes_customized,
		Bosses = are_bosses_customized,
		Ambients = are_ambients_customized,
		Specials = are_specials_customized,
	}
end

mod:hook_safe(MatchmakingStateHostGame, "on_enter", function()
	local dw_enabled, ons_enabled = mod.get_status()
	if dw_enabled or ons_enabled then
		local spawn_tweaks_settings = mod.is_spawn_tweaks_customized()
		local spawn_tweaks_customized = table.contains(spawn_tweaks_settings, true)
		if spawn_tweaks_customized then
			mod:chat_broadcast("NOTE: Some Spawn Tweaks settings are enabled")
			for kind, state in pairs(spawn_tweaks_settings) do
				if state then
					mod:chat_broadcast(string.format("%s are customized", kind))
				end
			end
		end
	end
end)
