local mod = get_mod("UnitExplorer")

local function spawn_package_to_player(unit)
	mod:echo("Creating a '%s'", unit)
	local player = Managers.player:local_player()
	local world = Managers.world:world("level_world")

	if world and player and player.player_unit then
		local player_unit = player.player_unit

		local position = Unit.local_position(player_unit, 0)
		local rotation = Unit.local_rotation(player_unit, 0)
		return World.spawn_unit(world, unit, position, rotation)
	end

	return nil
end

local function navgen()
	-- local world = Application.main_world()
	local world = Managers.world:world("level_world")
	local nav_gen = GwNavGeneration.create(world)
	-- Push seedpoints.
	for _, unit in pairs(World.units_by_resource(world, "core/gwnav/units/seedpoint/seedpoint")) do
		mod:echo("seedpoint %s", unit)
		GwNavGeneration.push_seed_point(nav_gen, Unit.local_position(unit, 0))
	end
	-- Push units.
	-- for _, unit in pairs(World.units_by_resource(world, "units/architecture/town/town_walkway_02")) do
	--     if not Unit.alive(unit) then goto continue end
	--     if (
	--         Unit.has_data(unit, "gwnavseedpoint") or
	--         Unit.has_data(unit, "GwNavBoxObstacle") or
	--         Unit.has_data(unit, "GwNavCylinderObstacle") or
	--         Unit.has_data(unit, "GwNavTagBox")
	--         ) then goto continue end
	--         if Unit.get_data(unit, "gwnavgenexcluded") then goto continue end
	--         for i=0, Unit.num_actors(unit)-1 do
	--             local actor = Unit.actor(unit, i)
	--             if actor and not Actor.is_static(actor) then
	--                 goto continue
	--             end
	--         end
	--
	--             mod:echo("mesh %s", unit)
	--         GwNavGeneration.push_meshes_fromunit(nav_gen, unit, false, false) -- consume_physics_mesh, consume_render_mesh
	--         ::continue::
	--     end

	GwNavGeneration.push_meshes_fromunit(nav_gen, mod.outlined_unit, true, true) -- consume_physics_mesh, consume_render_mesh

	local absolute_output_base_dir = "F:\\navmesh"
	local relative_output_dir = "level01"
	local sector_name = "sector01"
	local database_index = 1
	-- Generation.
	local ok = GwNavGeneration.generate(
		nav_gen,
		absolute_output_base_dir,
		relative_output_dir,
		sector_name,
		database_index,
		0.38, -- entity_radius
		1.6, -- entity_height
		60, -- slope_max
		0.5, -- step_max
		0.5, -- min_navigable_surface
		0.5, -- altitude_tolerance
		0.1, -- raster_precision
		3, -- cell_size
		1, -- height_field_sampling
		true -- consume_terrain
	)
	print("Generate result", ok)
	if ok then
		local absolute_path = absolute_output_base_dir .. "/" .. relative_output_dir .. "/" .. sector_name .. ".navdata"
		GwNavGeneration.add_navdata_to_world(GLOBAL_AI_NAVWORLD, absolute_path, database_index)
	end
	--GwNavGeneration.destroy(nav_gen) -- Can sometimes crash.
end

mod:command("create", "", function()
	spawn_package_to_player("units/architecture/town/town_walkway_02")
end)

mod:command("gen", "", function()
	navgen()
end)
