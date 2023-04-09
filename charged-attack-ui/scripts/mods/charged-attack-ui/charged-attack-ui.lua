local mod = get_mod("charged-attack-ui")
local definitions = mod:dofile("scripts/mods/charged-attack-ui/charged-attack-ui_definitions")
local ChargedAttackUI = class()

-- Reload the UI when mods are reloaded or a setting is changed.
local DO_RELOAD = true
function mod.on_setting_changed()
	DO_RELOAD = true
end

function ChargedAttackUI:init(ingame_ui_context)
	self.ui_renderer = ingame_ui_context.ui_renderer
	self.input_manager = ingame_ui_context.input_manager
	self:create_ui()
end

function ChargedAttackUI:create_ui()
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self.ui_widget = UIWidget.init(definitions.widget_definition)
	DO_RELOAD = false
end

function ChargedAttackUI:update()
	if DO_RELOAD then
		self:create_ui()
	end

	local player_manager = Managers.player
	local local_player = player_manager:local_player()
	local player_unit = local_player.player_unit
	local inventory_extension = ScriptUnit.extension(player_unit, "inventory_system")
	if not inventory_extension then
		self.ui_widget.content.is_charging = false
		return
	end
	local item_data, right_hand_weapon_extension, left_hand_weapon_extension =
		CharacterStateHelper.get_item_data_and_weapon_extensions(
			inventory_extension
		)

	if right_hand_weapon_extension then
		local current_action = right_hand_weapon_extension.current_action_settings
		if current_action then
			local allowed_chain_actions = current_action.allowed_chain_actions
			local charged_chain_actions = {}
			for _, action in ipairs(allowed_chain_actions) do
				if action.start_time > 0 then
					table.insert(charged_chain_actions, action)
				end
			end
			mod:dump(charged_chain_actions, "cca", 2)
			if current_action.minimum_hold_time then
				self.ui_widget.content.charged_level_text = string.format("%f", current_action.minimum_hold_time)
				self.ui_widget.content.is_charging = true
			end
		else
			self.ui_widget.content.is_charging = false
		end
	elseif left_hand_weapon_extension then
		mod:echo("left handed")
	else
		self.ui_widget.content.is_charging = false
	end
end

function ChargedAttackUI:draw(dt)
	local ui_renderer = self.ui_renderer
	local ui_scenegraph = self.ui_scenegraph
	local input_service = self.input_manager:get_service("ingame_menu")
	local ui_widget = self.ui_widget

	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt)
	UIRenderer.draw_widget(ui_renderer, ui_widget)
	UIRenderer.end_pass(ui_renderer)
end

function ChargedAttackUI:destroy()
	-- NOOP
end

-- INIT
mod:hook_safe(IngameHud, "init", function(self, ingame_ui_context)
	self._mod_charged_attack_ui = ChargedAttackUI:new(ingame_ui_context)
end)

-- HOOKS
mod:hook_safe(IngameHud, "update", function(self, dt, t)
	if not self._mod_charged_attack_ui then
		return
	end
	self._mod_charged_attack_ui:update()
	self._mod_charged_attack_ui:draw(dt)
end)

mod:hook_safe(IngameHud, "destroy", function(self)
	if not self._mod_charged_attack_ui then
		return
	end
	self._mod_charged_attack_ui:destroy()
end)
