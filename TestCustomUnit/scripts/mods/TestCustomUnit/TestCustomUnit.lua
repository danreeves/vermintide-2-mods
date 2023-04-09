-- luacheck: globals get_mod Actor Breeds BreedHitZonesLookup DamageUtils NetworkLookup Unit
local mod = get_mod("TestCustomUnit")

mod:echo("Loaded ~")

local actor_node = Actor.node
local unit_actor = Unit.actor

DamageUtils.create_hit_zone_lookup = function(unit, breed)
	local hit_zones = breed.hit_zones
	local hit_zones_lookup = {}

	for zone_name, zone in pairs(hit_zones) do
		for _, actor_name in ipairs(zone.actors) do
			local actor = unit_actor(unit, actor_name)

			if not actor then
				print("Actor ", actor_name .. " not found in ", breed.name)
			else
				local node = actor_node(actor)
				hit_zones_lookup[node] = {
					name = zone_name,
					prio = zone.prio,
					actor_name = actor_name,
				}
				hit_zones_lookup[breed.name] = true
			end
		end
	end

	breed.hit_zones_lookup = hit_zones_lookup
	local breed_name = breed.name
	BreedHitZonesLookup[breed_name] = hit_zones_lookup
end

local function get_hash(unit)
	local unit_name = tostring(unit)

	local id = string.gsub(unit_name, "%[Unit '#ID%[", "")

	return string.gsub(id, "%]'%]", "")
end

-- local unit_path = "units/mods/TestCustomUnit/we_spear"
local unit_path = "units/mods/TestCustomUnit/pumpkin"
-- local unit_hash = "db0a68cb4cb20b05"

-- Breeds.critter_rat.base_unit = unit_path

local nwlid = #NetworkLookup.husks + 1
NetworkLookup.husks[nwlid] = unit_path
NetworkLookup.husks[unit_path] = nwlid

mod:hook(Unit, "set_animation_root_mode", function(func, unit, mode)
	if get_hash(unit) == unit_hash then
		return
	end
	func(unit, mode)
end)

mod:hook(Unit, "animation_event", function(func, unit, event, ...)
	if get_hash(unit) == unit_hash then
		return
	end
	func(unit, event, ...)
end)

ItemMasterList.questing_knight_hat_0001.unit = unit_path

mod:hook(PackageManager, "load", function(func, self, package_name, reference_name, callback, asynchronous, prioritize)
	if package_name ~= unit_path then
		func(self, package_name, reference_name, callback, asynchronous, prioritize)
	end
end)

mod:hook(PackageManager, "unload", function(func, self, package_name, reference_name)
	if package_name ~= unit_path then
		func(self, package_name, reference_name)
	end
end)

mod:hook(PackageManager, "has_loaded", function(func, self, package, reference_name)
	if package == unit_path then
		return true
	end
	return func(self, package, reference_name)
end)

mod:hook(PackageManager, "force_load", function(func, self, package_name)
	if package_name ~= unit_path then
		return func(self, package_name)
	end
end)

-- mod:hook(PackageManager, "load", function (func, self, package_name, reference_name, callback, asynchronous, prioritize)
--   mod:echo(package_name)
--   if package_name ~= unit_path and package_name ~= unit_path .. "_3p" then
--     func(self, package_name, reference_name, callback, asynchronous, prioritize)
--   end
-- end)
--
-- mod:hook(PackageManager, "unload", function (func, self, package_name, reference_name)
--   if package_name ~= unit_path and package_name ~= unit_path .. "_3p"then
--     func(self, package_name, reference_name)
--   end
-- end)
--
-- mod:hook(PackageManager, "has_loaded", function (func, self, package, reference_name)
--   if package == unit_path or package == unit_path .. "_3p" then
--     return true
--   end
--   return func(self, package, reference_name)
-- end)

-- for k, v in pairs(WeaponSkins.skins) do
--   if string.starts_with(k,"we_spear_skin") then
--     v["right_hand_unit"] = unit_path
--   end
-- end
--
-- local nwlid = #NetworkLookup.inventory_packages + 1
-- NetworkLookup.inventory_packages[nwlid] = unit_path
-- NetworkLookup.inventory_packages[unit_path] = nwlid
--
-- nwlid = #NetworkLookup.inventory_packages + 1
-- NetworkLookup.inventory_packages[nwlid] = unit_path .. "_3p"
-- NetworkLookup.inventory_packages[unit_path .. "_3p"] = nwlid

-- local nwlid = #NetworkLookup.husks + 1
-- NetworkLookup.inventory_packages[nwlid] = unit_path
-- NetworkLookup.inventory_packages[unit_path] = nwlid

local function spawn_package_to_player(package_name)
	local player = Managers.player:local_player()
	local world = Managers.world:world("level_world")

	if world and player and player.player_unit then
		local player_unit = player.player_unit

		local position = Unit.local_position(player_unit, 0) + Vector3(0, 0, 1)
		local rotation = Unit.local_rotation(player_unit, 0)
		--- hacky may crash
		local unit_template_name = "interaction_unit" -- UnitResource.get_data(package_name, "unit_template")
		return Managers.state.unit_spawner:spawn_network_unit(package_name, unit_template_name, nil, position, rotation)
	end

	return nil
end

mod:command("spawn", "", function()
	spawn_package_to_player(unit_path)
end)

mod:command("clear", "", function()
	local world = Managers.world:world("level_world")
	local units = World.units_by_resource(world, unit_path)
	for i, unit in ipairs(units) do
		World.destroy_unit(world, unit)
	end
end)

-- mod:command("time", "", function(scale)
--   Managers.state.debug:set_time_scale(tonumber(scale))
-- end)
