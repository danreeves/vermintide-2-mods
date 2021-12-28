local mod = get_mod("TestArmatureAnim")

local unit_path = "content/units/connie"

local function spawn_package_to_player (package_name)
  local player = Managers.player:local_player()
  local world = Managers.world:world("level_world")

  if world and player and player.player_unit then
    local player_unit = player.player_unit

    local position = Unit.local_position(player_unit, 0) + Vector3(0, 0, 1)
    local rotation = Unit.local_rotation(player_unit, 0)
    local unit = World.spawn_unit(world, package_name, position, rotation)

    return unit
  end

  return nil
end

mod:command("testmodel", "", function()
    local unit = spawn_package_to_player(unit_path)
	Unit.set_material(unit, "Connie", "units/beings/player/empire_soldier_knight/skins/middenland/mtr_outfit_middenland")
	-- Unit.set_material(unit, "Connie", "content/units/Connie")
end)
