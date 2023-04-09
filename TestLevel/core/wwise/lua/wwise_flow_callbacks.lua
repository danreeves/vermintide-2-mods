local WwiseVisualization = require("core/wwise/lua/wwise_visualization")

WwiseFlowCallbacks = WwiseFlowCallbacks or {}

local M = WwiseFlowCallbacks

local Application = stingray.Application
local Matrix4x4 = stingray.Matrix4x4
local Quaternion = stingray.Quaternion
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local Wwise = stingray.Wwise
local WwiseWorld = stingray.WwiseWorld

local listener_map = nil
if Wwise then
	listener_map = {
		["Listener0"] = Wwise.LISTENER_0,
		["Listener1"] = Wwise.LISTENER_1,
		["Listener2"] = Wwise.LISTENER_2,
		["Listener3"] = Wwise.LISTENER_3,
		["Listener4"] = Wwise.LISTENER_4,
		["Listener5"] = Wwise.LISTENER_5,
		["Listener6"] = Wwise.LISTENER_6,
		["Listener7"] = Wwise.LISTENER_7,
	}
end

function M.wwise_load_bank(t)
	if not Wwise then
		return
	end

	local name = t.name or ""
	Wwise.load_bank(name)
end

function M.wwise_unit_load_bank(t)
	if not Wwise then
		return
	end

	local name = t.name or ""
	local unit = t.unit
	if unit then
		if name == "" then
			name = Unit.get_data(unit, "Wwise", "bank_name")
		end
		-- Allow this node to fail silently if bank name is empty. This is an internal-use
		-- node and newly placed Wwise Audio Source units will have the bank name empty and this node
		-- will trigger.
		if name ~= "" then
			Wwise.load_bank(name)
		end
	end
end

function M.wwise_unload_bank(t)
	if not Wwise then
		return
	end

	local name = t.name or ""
	Wwise.unload_bank(name)
end

function M.wwise_set_language(t)
	if not Wwise then
		return
	end

	local name = t.name or ""
	Wwise.set_language(name)
end

function M.wwise_set_listener_pose(t)
	if not Wwise then
		return
	end

	local position = t.position
	if not position then
		return
	end

	local listener = listener_map[t.listener]
	local rotation = t.rotation or Quaternion.identity()
	local pose = Matrix4x4.from_quaternion_position(rotation, position)
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.set_listener(wwise_world, listener, pose)
end

function M.wwise_move_listener_to_unit(t)
	if not Wwise then
		return
	end

	local unit = t.unit
	if not unit then
		return
	end

	local listener = listener_map[t.listener]
	local unit_node_index = 1
	if t.unit_node then
		unit_node_index = Unit.node(unit, t.unit_node)
	end
	local pose = Unit.world_pose(unit, unit_node_index)
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.set_listener(wwise_world, listener, pose)
end

function M.wwise_trigger_event(t)
	if not Wwise then
		return
	end

	local name = t.name or ""

	local unit = t.unit
	local r1, r2
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	-- handle different source options
	if unit then
		if name == "" then
			name = Unit.get_data(unit, "Wwise", "event_name") or ""
		end
		local unit_node_index = 1
		if t.unit_node then
			unit_node_index = Unit.node(unit, t.unit_node)
		end
		r1, r2 = WwiseWorld.trigger_event(wwise_world, name, unit, unit_node_index)
	else
		local position = t.position
		if position then
			r1, r2 = WwiseWorld.trigger_event(wwise_world, name, position)
		else
			local source_id = t.existing_source_id
			if source_id then
				r1, r2 = WwiseWorld.trigger_event(wwise_world, name, source_id)
			else
				-- no source specified (uses unpositioned source)
				r1, r2 = WwiseWorld.trigger_event(wwise_world, name)
			end
		end
	end
	return { playing_id = r1, source_id = r2 }
end

local function make_source(t, wwise_world_function)
	if not Wwise then
		return
	end

	local unit = t.unit
	local r1
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	-- handle different source options
	if unit then
		local unit_node_index = 1
		if t.unit_node then
			unit_node_index = Unit.node(unit, t.unit_node)
		end
		r1 = wwise_world_function(wwise_world, unit, unit_node_index)
	else
		local position = t.position
		if position then
			r1 = wwise_world_function(wwise_world, position)
		else
			local source_id = t.source_id
			if source_id then
				r1 = wwise_world_function(wwise_world, source_id)
			else
				-- no source specified (returns unpositioned source)
				r1 = wwise_world_function(wwise_world)
			end
		end
	end
	return r1
end

function M.wwise_make_auto_source(t)
	return { source_id = make_source(t, WwiseWorld.make_auto_source) }
end

function M.wwise_make_manual_source(t)
	return { source_id = make_source(t, WwiseWorld.make_manual_source) }
end

function M.wwise_destroy_manual_source(t)
	if not Wwise then
		return
	end

	local id = t.source_id
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.destroy_manual_source(wwise_world, id)
end

function M.wwise_stop_event(t)
	if not Wwise then
		return
	end

	local id = t.playing_id
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.stop_event(wwise_world, id)
end

function M.wwise_pause_event(t)
	if not Wwise then
		return
	end

	local id = t.playing_id
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.pause_event(wwise_world, id)
end

function M.wwise_resume_event(t)
	if not Wwise then
		return
	end

	local id = t.playing_id
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.resume_event(wwise_world, id)
end

function M.wwise_set_source_position(t)
	if not Wwise then
		return
	end

	local id = t.source_id
	local val = t.position
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.set_source_position(wwise_world, id, val)
end

function M.wwise_set_source_parameter(t)
	if not Wwise then
		return
	end

	local id = t.source_id
	local name = t.parameter_name or ""
	local val = t.value
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.set_source_parameter(wwise_world, id, name, val)
end

function M.wwise_set_global_parameter(t)
	if not Wwise then
		return
	end

	local name = t.parameter_name or ""
	local val = t.value
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.set_global_parameter(wwise_world, name, val)
end

function M.wwise_set_state(t)
	if not Wwise then
		return
	end
	if not t.group then
		return
	end
	if not t.state then
		return
	end

	local group = t.group
	local state = t.state
	Wwise.set_state(group, state)
end

function M.wwise_set_switch(t)
	if not Wwise then
		return
	end
	if not t.group then
		return
	end
	if not t.state then
		return
	end

	local group = t.group
	local state = t.state
	local id = t.source_id
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.set_switch(wwise_world, group, state, id)
end

function M.wwise_post_trigger(t)
	if not Wwise then
		return
	end

	local id = t.source_id
	local name = t.name
	if id and name then
		local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
		WwiseWorld.post_trigger(wwise_world, id, name)
	end
end

function M.wwise_has_source(t)
	if not Wwise then
		return
	end

	local id = t.source_id
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	if WwiseWorld.has_source(wwise_world, id) then
		return { yes = true }
	else
		return { no = true }
	end
end

function M.wwise_is_playing(t)
	if not Wwise then
		return
	end

	local id = t.playing_id
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	if WwiseWorld.is_playing(wwise_world, id) then
		return { yes = true }
	else
		return { no = true }
	end
end

function M.wwise_get_playing_elapsed(t)
	if not Wwise then
		return
	end

	local id = t.playing_id
	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	local elapsed_in_ms = WwiseWorld.get_playing_elapsed(wwise_world, id)
	if not elapsed_in_ms then
		elapsed_in_ms = 0
	end
	return { seconds = elapsed_in_ms / 1000 }
end

function M.wwise_add_soundscape_source(t)
	if not Wwise then
		return
	end

	local name = t.name or ""
	local unit = t.unit
	local shape = t.shape
	local positioning = t.positioning
	local trigger_range = t.trigger_range
	local result_id
	-- todo: handle different source options
	if unit then
		if name == "" then
			name = Unit.get_data(unit, "Wwise", "event_name") or ""
			if name == "" then
				print("Error: Wwise Add Soundscape Source. No event name specified.")
				return
			end
		end
		if not shape then
			shape = Unit.get_data(unit, "Wwise", "shape") or "point"
		end
		shape = string.lower(shape)
		local shape_map = {
			["point"] = Wwise.SHAPE_POINT,
			["sphere"] = Wwise.SHAPE_SPHERE,
			["box"] = Wwise.SHAPE_BOX,
		}
		shape = shape_map[shape] or Wwise.SHAPE_POINT
		if not positioning then
			positioning = string.lower(Unit.get_data(unit, "Wwise", "positioning")) or "closest"
		end
		local default_scale = 10
		local scale = default_scale
		if shape == Wwise.SHAPE_SPHERE then
			scale = t.sphere_radius
			if not scale then
				scale = Unit.get_data(unit, "Wwise", "sphere_radius") or default_scale
			end
		elseif shape == Wwise.SHAPE_BOX then
			scale = t.box_scale
			if not scale then
				scale = Vector3(0, 0, 0)
				scale.x = Unit.get_data(unit, "Wwise", "box_extents", 0) or default_scale
				scale.y = Unit.get_data(unit, "Wwise", "box_extents", 1) or default_scale
				scale.z = Unit.get_data(unit, "Wwise", "box_extents", 2) or default_scale
			end
		end
		local positioning_map = {
			["closest"] = Wwise.POSITIONING_CLOSEST_TO_LISTENER,
			["random in shape"] = Wwise.POSITIONING_RANDOM_IN_SHAPE,
			["random around listener"] = Wwise.POSITIONING_RANDOM_AROUND_LISTENER,
		}
		positioning = positioning_map[positioning] or Wwise.POSITIONING_CLOSEST_TO_LISTENER
		local unit_node_index = 1
		if t.unit_node then
			unit_node_index = Unit.node(unit, t.unit_node)
		end
		local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
		result_id = WwiseWorld.add_soundscape_unit_source(
			wwise_world,
			name,
			unit,
			unit_node_index,
			shape,
			scale,
			positioning,
			0,
			5,
			trigger_range
		)
	end
	return { ss_source_id = result_id }
end

function M.wwise_remove_soundscape_source(t)
	if not Wwise then
		return
	end

	local id = t.ss_source_id
	if not id then
		print("Error: nil soundscape source id, removing soundscape source failed.")
		return
	end

	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.remove_soundscape_source(wwise_world, id)
end

function M.wwise_set_obstruction_and_occlusion_for_soundscape_source(t)
	if not Wwise then
		return
	end

	local id = t.ss_source_id
	local obstruction = t.obstruction or 0
	local occlusion = t.occlusion or 0

	if id then
		local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
		WwiseWorld.set_obstruction_and_occlusion_for_soundscape_source(wwise_world, id, obstruction, occlusion)
	end
end

function M.wwise_add_soundscape_render_unit(t)
	if not Wwise then
		return
	end

	local unit = t.unit
	if unit then
		WwiseVisualization.add_soundscape_unit(unit)
	end
end

function M.wwise_set_environment(t)
	if not Wwise then
		return
	end

	local name = t.aux_bus
	local value = t.value
	if name and value then
		local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
		WwiseWorld.set_environment(wwise_world, name, value)
	end
end

function M.wwise_set_dry_environment(t)
	if not Wwise then
		return
	end

	local value = t.value
	if value then
		local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
		WwiseWorld.set_dry_environment(wwise_world, value)
	end
end

function M.wwise_reset_environment(t)
	if not Wwise then
		return
	end

	local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
	WwiseWorld.reset_environment(wwise_world)
end

function M.wwise_set_source_environment(t)
	if not Wwise then
		return
	end

	local id = t.source_id
	local name = t.aux_bus
	local value = t.value
	if id and name and value then
		local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
		WwiseWorld.set_environment_for_source(wwise_world, id, name, value)
	end
end

function M.wwise_set_source_dry_environment(t)
	if not Wwise then
		return
	end

	local id = t.source_id
	local value = t.value
	if id and value then
		local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
		WwiseWorld.set_dry_environment_for_source(wwise_world, id, value)
	end
end

function M.wwise_reset_source_environment(t)
	if not Wwise then
		return
	end

	local id = t.source_id
	if id then
		local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
		WwiseWorld.reset_environment_for_source(wwise_world, id)
	end
end

function M.wwise_set_obstruction_and_occlusion(t)
	if not Wwise then
		return
	end

	local id = t.source_id
	local listener = listener_map[t.listener]
	local obstruction = t.obstruction or 0
	local occlusion = t.occlusion or 0
	if id and listener then
		local wwise_world = Wwise.wwise_world(Application.flow_callback_context_world())
		WwiseWorld.set_obstruction_and_occlusion(wwise_world, listener, id, obstruction, occlusion)
	end
end
