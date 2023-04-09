-- luacheck: globals get_mod Managers Unit Vector3 POSITION_LOOKUP IngameUI ScriptWorld ScriptViewport Camera UIRenderer Color UIResolution Gui VMFOptionsView ColorPicker ScriptUnit CameraStateFollowThirdPerson CameraStateObserver Application math.clamp
local mod = get_mod("MMONames2")
mod.player_colors = {}

mod:dofile("scripts/mods/MMONames2/ColorPicker")
mod:dofile("scripts/mods/MMONames2/NetworkColours")

local fonts = {
	{ name = "gw_body", size_mod = 2 },
	{ name = "gw_head", size_mod = 4 },
	{ name = "arial", size_mod = 0 },
}

local function draw_icon(renderer, unit, camera, player_position)
	if not Unit.alive(unit.player_unit) then
		return
	end

	local font_index = mod:get("font")
	local font_name = fonts[font_index].name
	local font_material = "materials/fonts/" .. font_name

	local head_node = Unit.has_node(unit.player_unit, "c_head") and Unit.node(unit.player_unit, "c_head")
	local head_pos = Unit.world_position(unit.player_unit, head_node)

	if not head_pos then
		return
	end

	local min_render_distance = mod:get("min_render_distance") or 0
	local max_render_distance = mod:get("max_render_distance") or 255

	-- Compute the distance
	local distance = Vector3.distance(head_pos, player_position)
	if distance > max_render_distance or distance < min_render_distance then
		return
	end

	-- Position slightly above
	head_pos = head_pos + Vector3(0, 0, 0.333)

	-- Compute the screen position.
	--  The depth value indicates the depth into the screen where the point lies (the distance from the camera plane)
	local screen_pos, depth = Camera.world_to_screen(camera, head_pos)

	-- Check if the position is behind the camera plane.
	if depth >= 1 then
		return
	end

	-- Compute derived values.
	local arbitrary_max_distance_cutoff = 100
	local scale = math.clamp(1 - distance / arbitrary_max_distance_cutoff, 0, 1)
	local alpha = mod:get("transparent_at_distance")
			and math.clamp(1 - distance / arbitrary_max_distance_cutoff, 0.1, 1.0) * 255
		or 255

	local screen_w, _ = UIResolution()
	local render_scale = 1920 / screen_w
	if screen_w > 1920 and Application.user_setting("hud_clamp_ui_scaling") then
		render_scale = math.max(render_scale, 1)
	end
	local font_render_scale = screen_w / 1920 -- Font size needs to increase
	local min_font_size = mod:get("min_font_size") * font_render_scale
	local max_font_size = mod:get("max_font_size") * font_render_scale
	local font_size = math.clamp(max_font_size * scale, min_font_size, max_font_size) + fonts[font_index].size_mod
	local player_color = mod.get_player_color(unit)
	local color = { alpha, player_color[1], player_color[2], player_color[3] }
	local name = unit:name()
	local text = ""

	if mod:get("show_name") then
		text = text .. name
	end

	if mod:get("show_health") then
		local player_unit = unit.player_unit
		local health_ext = ScriptUnit.extension(player_unit, "health_system")
		local health_percent = health_ext:current_health_percent()
		if health_percent then
			text = text .. string.format(" [%d%%]", math.floor(health_percent * 100))
		end
	end

	local min, max = Gui.text_extents(renderer.gui, text, font_material, font_size)
	local size = max - min
	local position = Vector3(
		(screen_pos[1] - (size.x / 2)) * render_scale,
		(screen_pos[2] - (size.y / 2)) * render_scale,
		0
	)

	if mod:get("show_career_icon") then
		local career_ext = ScriptUnit.extension(unit.player_unit, "career_system")
		if career_ext then
			-- Offset by half the icon width
			position = position + Vector3(font_size / 3, 0, 0)

			local career_name = career_ext:career_name()

			if career_name == "wh_priest" then
				career_name = "wh_warriorpriest"
			end

			local icon = "copy_store_tag_icon_" .. career_name

			local icon_position = position - Vector3(font_size, font_size / 3, 0)
			local icon_size = { font_size, font_size }
			UIRenderer.draw_texture(renderer, icon, icon_position, icon_size, color)
		end
	end

	if mod:get("text_shadow") then
		local offset = math.clamp(font_size / 30, 1, 3)
		UIRenderer.draw_text(
			renderer,
			text,
			font_material,
			font_size,
			font_name,
			position + Vector3(offset, -offset, 0),
			{ alpha, 0, 0, 0 }
		)
	end

	UIRenderer.draw_text(renderer, text, font_material, font_size, font_name, position, color)
end

function mod.get_player_color(player)
	local current_player = Managers.player:local_player()
	-- Bots are white
	if not player:is_player_controlled() then
		return { 255, 255, 255 }
	end
	if player == current_player or mod:get("color_override") then
		return { mod:get("user_color_r"), mod:get("user_color_g"), mod:get("user_color_b") }
	end
	return mod.player_colors[player.peer_id] or { 255, 255, 255 }
end

function mod.get_camera(player)
	local world = Managers.world:world("level_world")
	local viewport = ScriptWorld.viewport(world, player.viewport_name)
	local camera = ScriptViewport.camera(viewport)

	return camera
end

mod.is_in_third_person = false
mod.is_in_third_person_timeout = 0

mod:hook_safe(CameraStateFollowThirdPerson, "update", function(self, _, _, _, _, t)
	if self.name == "follow_third_person" then
		mod.is_in_third_person = true
		mod.is_in_third_person_timeout = t + 0.5
	else
		mod.is_in_third_person = false
	end
end)

mod.spectated_unit = nil

mod:hook_safe(CameraStateObserver, "_set_follow_unit", function(_, _, unit)
	mod.spectated_unit = unit
end)

mod:hook_safe(CameraStateObserver, "on_exit", function()
	mod.spectated_unit = nil
end)

mod:hook_safe(IngameUI, "post_update", function(self, _, t)
	local renderer = self.ui_renderer
	local current_player = Managers.player:local_player()
	local player_unit = current_player.player_unit
	if not (player_unit or mod.spectated_unit) then
		return
	end

	if mod.is_in_third_person then
		if mod.is_in_third_person_timeout <= t then
			mod.is_in_third_person = false
		end
	end

	local player_status = Managers.party:get_player_status(current_player.peer_id, current_player._local_player_id)
	local health_state = player_status.game_mode_data.health_state
	if health_state == "respawn" then
		mod.is_in_third_person = true
	end

	local players = Managers.player:human_and_bot_players()
	local display_own_name = mod:get("display_own_name")
	local camera = mod.get_camera(current_player)

	-- If the player is dead and spectating then we want to base distance
	-- calculations on the spectated player position, i.e. where the camera is
	local player_position
	if mod.spectated_unit then
		player_position = POSITION_LOOKUP[mod.spectated_unit]
	end

	if not player_position then
		player_position = POSITION_LOOKUP[player_unit]
	end

	if not player_position then
		return
	end

	for _, player in pairs(players) do
		local draw_player_name = player ~= current_player or (display_own_name and mod.is_in_third_person)
		if draw_player_name then
			draw_icon(renderer, player, camera, player_position)
		end
	end
end)
