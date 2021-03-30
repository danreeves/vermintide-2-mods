-- luacheck: globals Unit get_mod Vector3Box QuaternionBox Managers
-- luacheck: globals Vector3 Quaternion Color
local mod = get_mod("UnitExplorer")

function mod.unit_hash(unit)
    local debug_name = Unit.debug_name(unit)
    debug_name = string.gsub(debug_name, "#ID%[", "")
    debug_name = string.gsub(debug_name, "%]", "")
    return debug_name
end

function mod.extract_unit_data(unit)
    local data = {}
    if Unit.alive(unit) then
        data.unit = unit
        data.name = (Unit.get_data(unit, "unit_name") or "")
        data.id = tostring(Unit.id(unit))
        data.hash = mod.unit_hash(unit)
        if Unit.num_scene_graph_items(unit) > 0 then
            data.position = Vector3Box(Unit.world_position(unit, 0))
            data.rotation = QuaternionBox(Unit.world_rotation(unit, 0))
        end

        data.extensions = {}
        local j = 0
        while Unit.has_data(unit, "extensions", j) do
            local class_name = Unit.get_data(unit, "extensions", j)
            j = j + 1
            data.extensions[j] = class_name
        end

        data.from_game_mode = Unit.get_data(unit, "from_game_mode")
        -- data.has_idle_anim = Unit.has_animation_event(unit, "idle")
        -- data.has_animation_state_machine = Unit.has_animation_state_machine(unit)
        -- data.bone_mode = Unit.animation_bone_mode(unit)
    end

    return data
end

function mod.drag_unit(unit_explorer)
    local player_manager = Managers.player
    local local_player = player_manager:local_player()
    local viewport_name = local_player.viewport_name
    local camera_position = Managers.state.camera:camera_position(viewport_name)
    local camera_rotation = Managers.state.camera:camera_rotation(viewport_name)
    local camera_direction = Quaternion.forward(camera_rotation)

    local unit = mod.outlined_unit
    local new_position =
    camera_position + Vector3.normalize(camera_direction) *
    mod.dragged_unit_distance


    local rotation = mod.dragged_rotation:unbox()

    Unit.set_local_position(unit, 0, new_position)
    Unit.set_local_rotation(unit, 0, rotation)

    -- Force the physics to update
    Unit.disable_physics(unit)
    Unit.enable_physics(unit)

    -- Prevent stale data
    mod.dragged_rotation = QuaternionBox(rotation)
end

function mod.outline_unit(unit)
    local flag = "outline_unit"
    local channel = Color(255, 0, 0, 255)
    local apply_method = "unit_and_childs"
    local outline_system = Managers.state.entity:system("outline_system")
    local do_outline = true
    outline_system:outline_unit(unit, flag, channel, do_outline, apply_method)
end
