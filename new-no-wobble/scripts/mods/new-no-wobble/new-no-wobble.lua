local mod = get_mod("new-no-wobble")

function mod.update()
  if mod:is_enabled() and Managers.state.network ~= nil and Unit.alive(Managers.player:local_player().player_unit) then
    local first_person_ext = ScriptUnit.extension(Managers.player:local_player().player_unit, "first_person_system")
    local first_person_unit = first_person_ext.get_first_person_unit(first_person_ext)
    local camera_node = Unit.node(first_person_unit, "camera_node")

    Unit.set_local_rotation(first_person_unit, camera_node, Quaternion.identity())
    Unit.set_local_position(first_person_unit, camera_node, Vector3.zero())
  end
end
