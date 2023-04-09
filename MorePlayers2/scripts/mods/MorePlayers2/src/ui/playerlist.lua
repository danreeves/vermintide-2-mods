-- luacheck: globals get_mod UnitFramesHandler UnitFrameUI Managers World
-- luacheck: globals UIResolution UISettings Vector3 UIRenderer table.is_empty
-- luacheck: globals math.clamp
local mod = get_mod("MorePlayers2")

local fonts = {
	{ name = "arial", size_mod = 0 },
	{ name = "gw_body", size_mod = 2 },
	{ name = "gw_head", size_mod = 4 },
}

mod:hook(UnitFramesHandler, "_create_unit_frame_by_type", function(func, self, frame_type, frame_index)
	local unit_frame = func(self, frame_type, frame_index)
	-- Store the frame_type so we can tell if it's the current player
	unit_frame.frame_type = frame_type
	return unit_frame
end)

mod:hook(UnitFramesHandler, "_draw", function(func, self, dt)
	if not mod:get("show_player_list") then
		return
	end

	if mod:get("use_default_player_list") then
		return func(self, dt)
	end

	if not self._is_visible then
		return
	end

	local ingame_ui_context = self.ingame_ui_context
	local ui_renderer = ingame_ui_context.ui_renderer

	if not mod.gui then
		local world = Managers.world:world("top_ingame_view")
		mod.gui = World.create_screen_gui(world, "material", "materials/fonts/gw_fonts", "immediate")
	end

	local font_index = mod:get("font")
	local font = fonts[font_index].name
	local font_material = "materials/fonts/" .. font
	local base_font_size = mod:get("font_size") + fonts[font_index].size_mod
	local base_line_height = base_font_size * 1.4
	local WHITE = { 255, 255, 255, 255 }
	local BLACK = { 255, 0, 0, 0 }

	local screen_w, _ = UIResolution()
	local unit_frames = self._unit_frames

	local font_size = base_font_size * (screen_w / 1920)
	local line_height = base_line_height * (screen_w / 1920)
	local icon_size = { font_size * 1.5, font_size * 1.5 }

	local not_visible = 0
	for i = 1, #unit_frames, 1 do
		local unit_frame = unit_frames[i]

		if unit_frame.frame_type == "player" then
			unit_frame.widget:draw(dt)
			not_visible = not_visible + 1
		else
			local data = unit_frame.data
			local player_data = unit_frame.player_data
			local widget = unit_frame.widget

			if table.is_empty(data) then
				not_visible = not_visible + 1
			else
				local hud_scale_multiplier = UISettings.use_custom_hud_scale and UISettings.hud_scale * 0.01 or 1.0
				local top = 1080 / hud_scale_multiplier
				local visible_i = i - not_visible
				local left_padding = line_height * 1.3
				local pos = Vector3(left_padding, top - (visible_i * line_height), 0)
				local text = data.display_name or ""
				local color = WHITE
				local shadow = BLACK

				if mod:get("use_mmo_names_colors") then
					if mod.mmo_names and player_data then
						if player_data.peer_id and player_data.player and player_data.player:is_player_controlled() then
							local player_color = mod.mmo_names.player_colors[player_data.peer_id]
							if player_color then
								color = { 255, player_color[1], player_color[2], player_color[3] }
							end
						end
					end
				end

				local career_name
				if not data.is_dead then
					local extensions = player_data.extensions
					if extensions then
						local career_extension = extensions.career
						if career_extension then
							career_name = career_extension:career_name()
						end
					end
				end

				local health_widget = widget:_widget_by_feature("health", "dynamic")
				local health_content = health_widget.content
				local health_bar_content = health_content.total_health_bar

				local show_health = health_bar_content.draw_health_bar
				local is_wounded = health_bar_content.is_wounded

				local default_widget = widget:_widget_by_feature("default", "dynamic")
				local default_content = default_widget.content
				local is_connecting = default_content.connecting

				local equipment_widget = widget:_widget_by_feature("equipment", "dynamic")
				local equipment_widget_content = nil
				if equipment_widget ~= nil then
					equipment_widget_content = equipment_widget.content
				end

				local health_percent = nil
				if show_health and not is_connecting then
					local extensions = player_data.extensions
					if extensions then
						local health_extension = extensions.health
						if health_extension then
							health_percent = math.floor((health_extension:current_health_percent() or 0) * 100)
						end
					end
				end

				if mod:get("show_hp") then
					if not is_connecting and not data.assisted_respawn and not data.is_dead and health_percent then
						text = text .. string.format(" [%d%%]", math.clamp(health_percent, 1, 100))
					end
				end

				if is_connecting then
					text = text .. " [Connecting]"
					color = { 75, 255, 255, 255 }
				elseif data.needs_help then
					text = text .. " [Help!]"
					color = { 255, 255, 165, 0 }
				elseif data.is_knocked_down then
					text = text .. " [Down]"
					color = { 255, 255, 0, 0 }
				elseif data.assisted_respawn then
					text = text .. " [Respawned]"
					color = { 50, 255, 255, 255 }
					shadow = { 5, 0, 0, 0 }
				elseif data.is_dead then
					text = text .. " [Dead]"
					color = { 50, 255, 255, 255 }
					shadow = { 5, 0, 0, 0 }
				end

				-- Career icon
				if career_name then
					local icon_name = career_name

					if icon_name == "wh_priest" then
						icon_name = "wh_warriorpriest"
					end

					local icon = "moreplayers2_store_tag_icon_" .. icon_name
					local icon_position = pos - Vector3(font_size + left_padding * 0.3, font_size / 3, 0)
					UIRenderer.draw_texture(ui_renderer, icon, icon_position, icon_size, color)
				end

				-- Text shadow
				local shadow_font_size = font_size + (0.1 / hud_scale_multiplier)
				local shadow_pos = pos + Vector3(0.6 / hud_scale_multiplier, -(1.5 / hud_scale_multiplier), 0)
				UIRenderer.draw_text(ui_renderer, text, font_material, shadow_font_size, font, shadow_pos, shadow)

				-- Text
				UIRenderer.draw_text(ui_renderer, text, font_material, font_size, font, pos, color)

				local width = UIRenderer.text_size(ui_renderer, text, font_material, font_size)
				local icon_position = pos + Vector3(width - font_size + font_size * 0.25, -(font_size / 3.5), 0)
				local bg_scale = font_size / 20

				-- Wounded icon
				if show_health and is_wounded then
					icon_position = icon_position + Vector3(font_size, 0, 0)
					local bg_icon_position = icon_position - Vector3(bg_scale, bg_scale, 0)
					local bg_icon_size = { icon_size[1] + bg_scale * 2, icon_size[2] + bg_scale * 2 }
					UIRenderer.draw_texture(
						ui_renderer,
						"tabs_icon_all_selected",
						bg_icon_position,
						bg_icon_size,
						BLACK
					)
					UIRenderer.draw_texture(ui_renderer, "tabs_icon_all_selected", icon_position, icon_size, WHITE)
				end

				if equipment_widget then
					for index = 1, 3, 1 do
						local slot = "item_slot_" .. index
						local icon = equipment_widget_content[slot]
						local icon_color = WHITE
						if icon and icon ~= "icons_placeholder" then
							local show_heals = mod:get("show_healing_items") and string.find(icon, "heal")
							local show_books = (
								mod:get("show_books") and (string.find(icon, "tome") or string.find(icon, "grim"))
							)
							local show_pots = mod:get("show_pots") and string.find(icon, "potion")
							local show_bombs = mod:get("show_bombs") and string.find(icon, "bomb")

							if show_heals or show_books or show_pots or show_bombs then
								icon_position = icon_position + Vector3(icon_size[1], 0, 0)

								local better_icon_table = {
									heal_01 = "hud_icon_heal_01",
									heal_02 = "hud_icon_heal_02",
									speed = "hud_icon_potion_speed",
									strength = "hud_icon_potion_strength",
									cooldown = "hud_icon_potion_cooldown_reduction",
									["bomb$"] = "hud_icon_bomb_01",
									bomb_2 = "hud_icon_bomb_02",
									tome = "hud_icon_tome",
									grim = "hud_icon_grimoire",
									LiquidBravado = "hud_inventory_icon_deuspotion_LiquidBravado_02",
									VampiricDraught = "hud_inventory_icon_deuspotion_VampiricDraught_02",
									MootMilk = "hud_inventory_icon_deuspotion_MootMilk_02",
									FriendlyMurderer = "hud_inventory_icon_deuspotion_FriendlyMurderer_02",
									KillerInTheShadows = "hud_inventory_icon_deuspotion_KillerInTheShadows_02",
									PocketsFullOfBombs = "hud_inventory_icon_deuspotion_PocketsFullOfBombs_02",
									HoldMyBeer = "hud_inventory_icon_deuspotion_HoldMyBeer_02",
									hud_inventory_icon_deuspotion_PoisonProof = "hud_inventory_icon_deuspotion_PoisonProof_02",
								}

								local color_table = {
									speed = { 255, 0, 200, 255 },
									strength = { 255, 255, 200, 0 },
									cooldown = { 255, 225, 0, 255 },
									heal = { 255, 0, 200, 0 },
									bomb = { 255, 255, 255, 255 },
									tome = { 255, 200, 0, 0 },
									grim = { 255, 200, 0, 0 },
									deuspotion = { 255, 200, 0, 0 },
								}

								for test, icn in pairs(better_icon_table) do
									if string.find(icon, test) then
										icon = icn
										break
									end
								end

								for test, col in pairs(color_table) do
									if string.find(icon, test) then
										icon_color = col
										break
									end
								end

								if icon == "hud_icon_bomb_02" then
									local x_offset = icon_size[1] * 0.15
									local y_offset = icon_size[2] * 0.15
									local shadow_icon_size = { icon_size[1] + x_offset, icon_size[2] + y_offset }
									local shadow_icon_position = icon_position - Vector3(x_offset / 2, y_offset / 2, 0)
									UIRenderer.draw_texture(
										ui_renderer,
										icon .. "_glow",
										shadow_icon_position,
										shadow_icon_size,
										BLACK
									)
								else
									UIRenderer.draw_texture(
										ui_renderer,
										icon .. "_glow",
										icon_position,
										icon_size,
										BLACK
									)
								end
								UIRenderer.draw_texture(ui_renderer, icon, icon_position, icon_size, icon_color)
							end
						end
					end
				end
			end
		end
	end
end)
