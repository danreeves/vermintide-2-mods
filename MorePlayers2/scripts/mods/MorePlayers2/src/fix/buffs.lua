-- luacheck: globals get_mod ScriptUnit BuffFunctionTemplates Managers POSITION_LOOKUP Unit Vector3
local mod = get_mod("MorePlayers2")

local function players_of_career(career, player_and_bot_units, owner)
	-- Store the footknights to check distances
	local players = {}
	for i = 1, #player_and_bot_units, 1 do
		local unit = player_and_bot_units[i]
		local career_extension = ScriptUnit.extension(unit, "career_system")
		local career_name = career_extension:career_name()
		if career_name == career and unit ~= owner then
			table.insert(players, unit)
		end
	end
	return players
end

local function has_one_in_range(players, current_unit_position, range_squared)
	local has_one = false
	for j = 1, #players, 1 do
		local player = players[j]
		local player_pos = POSITION_LOOKUP[player]
		local dist_to_fk = Vector3.distance_squared(player_pos, current_unit_position)

		if range_squared > dist_to_fk then
			has_one = true
		end
	end
	return has_one
end

-- In these functions we do two things to calm down the buff system:
--
-- 1. Stop trying to remove the buff from a unit of the same career.
--    They will just add it back and cause too many buffs
-- 2. Stop trying to remove from any unit too far away from the current unit.
--    First check if they have any other units of the same career near enough
--    to add the buff and don't remove it if they do.
--    They will just add it back and cause too many buffs

mod:hook_origin(
	BuffFunctionTemplates.functions,
	"markus_knight_proximity_buff_update",
	function(owner_unit, buff, params)
		if not Managers.state.network.is_server then
			return
		end

		local template = buff.template
		local range = buff.range
		local range_squared = range * range
		local owner_position = POSITION_LOOKUP[owner_unit]
		local side = Managers.state.side.side_by_unit[owner_unit]
		local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
		local num_units = #player_and_bot_units
		local talent_extension = ScriptUnit.extension(owner_unit, "talent_system")
		local buff_to_add = "markus_knight_passive_defence_aura"
		local buff_system = Managers.state.entity:system("buff_system")
		local power_talent = talent_extension:has_talent("markus_knight_guard")
		local range_talent = talent_extension:has_talent("markus_knight_passive_block_cost_aura")

		-- Store the footknights to check distances
		local footknights = players_of_career("es_knight", player_and_bot_units, owner_unit)

		for i = 1, num_units, 1 do
			local unit = player_and_bot_units[i]

			if Unit.alive(unit) then
				local unit_position = POSITION_LOOKUP[unit]
				local distance_squared = Vector3.distance_squared(owner_position, unit_position)
				local buff_extension = ScriptUnit.extension(unit, "buff_system")

				-- If the buff target is a FK we never want to do this block.
				-- They buff themself and we don't want to remove it
				if career_name ~= "es_knight" then
					if range_squared < distance_squared or power_talent or range_talent then
						-- Don't remove if another FK is in range
						local has_a_fk_in_range = has_one_in_range(footknights, unit_position, range_squared)
						if not has_a_fk_in_range then
							local buff = buff_extension:get_non_stacking_buff(buff_to_add)

							if buff then
								local buff_id = buff.server_id

								if buff_id then
									buff_system:remove_server_controlled_buff(unit, buff_id)
								end
							end
						end
					end
				end

				if
					distance_squared < range_squared
					and not power_talent
					and not range_talent
					and not buff_extension:has_buff_type(buff_to_add)
				then
					local server_buff_id = buff_system:add_buff(unit, buff_to_add, owner_unit, true)
					local buff = buff_extension:get_non_stacking_buff(buff_to_add)

					if buff then
						buff.server_id = server_buff_id
					end
				end
			end
		end
	end
)

-- Handles Handmaiden and Huntsman
mod:hook_origin(BuffFunctionTemplates.functions, "activate_buff_on_distance", function(owner_unit, buff, params)
	if not Managers.state.network.is_server then
		return
	end

	local template = buff.template
	local range = buff.range
	local range_squared = range * range
	local owner_position = POSITION_LOOKUP[owner_unit]
	local buff_to_add = template.buff_to_add
	local buff_system = Managers.state.entity:system("buff_system")
	local side = Managers.state.side.side_by_unit[owner_unit]
	local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
	local num_units = #player_and_bot_units

	local owner_career_ext = ScriptUnit.extension(owner_unit, "career_system")
	local owner_career_name = owner_career_ext:career_name()
	local same_career_units = players_of_career(owner_career_name, player_and_bot_units, owner_unit)

	for i = 1, num_units, 1 do
		local unit = player_and_bot_units[i]

		if Unit.alive(unit) then
			local unit_position = POSITION_LOOKUP[unit]
			local distance_squared = Vector3.distance_squared(owner_position, unit_position)
			local buff_extension = ScriptUnit.extension(unit, "buff_system")
			local career_extension = ScriptUnit.extension(unit, "career_system")
			local career_name = career_extension:career_name()

			-- Don't try removing a buff from a unit of the same career since they
			-- add it to themself anyway.
			if career_name ~= owner_career_name then
				if range_squared < distance_squared then
					-- Don't remove if another career of the same type is in range
					local has_a_same_career_in_range = has_one_in_range(same_career_units, unit_position, range_squared)
					if not has_a_same_career_in_range then
						local buff = buff_extension:get_non_stacking_buff(buff_to_add)

						if buff then
							local buff_id = buff.server_id

							if buff_id then
								buff_system:remove_server_controlled_buff(unit, buff_id)
							end
						end
					end
				end
			end

			if distance_squared < range_squared and not buff_extension:has_buff_type(buff_to_add) then
				local server_buff_id = buff_system:add_buff(unit, buff_to_add, owner_unit, true)
				local buff = buff_extension:get_non_stacking_buff(buff_to_add)

				if buff then
					buff.server_id = server_buff_id
				end
			end
		end
	end
end)

-- Handle IB, HM buff for x nearby allies talents
mod:hook_origin(
	BuffFunctionTemplates.functions,
	"activate_buff_stacks_based_on_ally_proximity",
	function(unit, buff, params)
		if not Managers.state.network.is_server then
			return
		end

		local buff_extension = ScriptUnit.extension(unit, "buff_system")
		local buff_system = Managers.state.entity:system("buff_system")
		local template = buff.template
		local range = buff.range
		local range_squared = range * range
		local chunk_size = template.chunk_size
		local buff_to_add = template.buff_to_add
		local max_stacks = template.max_stacks -- MODIFIED. Fixed bad reference. max_stacks is on template not buff
		local side = Managers.state.side.side_by_unit[unit]
		local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
		local own_position = POSITION_LOOKUP[unit]
		local num_nearby_allies = 0
		local allies = #player_and_bot_units

		-- MODIFIED. Max stacks is actually 3 but the buff template says 4 :(
		max_stacks = 3

		for i = 1, allies, 1 do
			local ally_unit = player_and_bot_units[i]

			if ally_unit ~= unit then
				local ally_position = POSITION_LOOKUP[ally_unit]
				local distance_squared = Vector3.distance_squared(own_position, ally_position)

				if distance_squared < range_squared then
					num_nearby_allies = num_nearby_allies + 1
				end

				if math.floor(num_nearby_allies / chunk_size) == max_stacks then
					break
				end
			end
		end

		if not buff.stack_ids then
			buff.stack_ids = {}
		end

		local num_chunks = math.floor(num_nearby_allies / chunk_size)
		local num_buff_stacks = buff_extension:num_buff_type(buff_to_add)

		if num_buff_stacks < num_chunks then
			local difference = num_chunks - num_buff_stacks

			for i = 1, difference, 1 do
				local buff_id = buff_system:add_buff(unit, buff_to_add, unit, true)
				local stack_ids = buff.stack_ids
				stack_ids[#stack_ids + 1] = buff_id
			end
		elseif num_chunks < num_buff_stacks then
			local difference = num_buff_stacks - num_chunks

			for i = 1, difference, 1 do
				local stack_ids = buff.stack_ids
				local buff_id = table.remove(stack_ids, 1)

				buff_system:remove_server_controlled_buff(unit, buff_id)
			end
		end
	end
)

mod:hook_origin(
	BuffFunctionTemplates.functions,
	"activate_party_buff_stacks_on_ally_proximity",
	function(owner_unit, buff, params)
		if not Managers.state.network.is_server then
			return
		end

		local buff_system = Managers.state.entity:system("buff_system")
		local template = buff.template
		local range = buff.range
		local range_squared = range * range
		local chunk_size = template.chunk_size
		local buff_to_add = template.buff_to_add
		local max_stacks = template.max_stacks -- MODIFIED: max_stacks comes from template, not buff
		local side = Managers.state.side.side_by_unit[owner_unit]
		local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
		local own_position = POSITION_LOOKUP[owner_unit]
		local num_nearby_allies = 0
		local allies = #player_and_bot_units

		for i = 1, allies, 1 do
			local ally_unit = player_and_bot_units[i]

			if ally_unit ~= owner_unit then
				local ally_position = POSITION_LOOKUP[ally_unit]
				local distance_squared = Vector3.distance_squared(own_position, ally_position)

				if distance_squared < range_squared then
					num_nearby_allies = num_nearby_allies + 1
				end

				if math.floor(num_nearby_allies / chunk_size) == max_stacks then
					break
				end
			end
		end

		if not buff.stack_ids then
			buff.stack_ids = {}
		end

		for i = 1, allies, 1 do
			local unit = player_and_bot_units[i]

			if ALIVE[unit] then
				if not buff.stack_ids[unit] then
					buff.stack_ids[unit] = {}
				end

				local unit_position = POSITION_LOOKUP[unit]
				local distance_squared = Vector3.distance_squared(own_position, unit_position)
				local buff_extension = ScriptUnit.extension(unit, "buff_system")

				if range_squared < distance_squared then
					local stack_ids = buff.stack_ids[unit]

					for i = 1, #stack_ids, 1 do
						local stack_ids = buff.stack_ids[unit]
						local buff_id = table.remove(stack_ids)

						buff_system:remove_server_controlled_buff(unit, buff_id)
					end
				else
					local num_chunks = math.floor(num_nearby_allies / chunk_size)
					local num_buff_stacks = buff_extension:num_buff_type(buff_to_add)

					if num_buff_stacks < num_chunks then
						local difference = num_chunks - num_buff_stacks
						local stack_ids = buff.stack_ids[unit]

						for i = 1, difference, 1 do
							local buff_id = buff_system:add_buff(unit, buff_to_add, unit, true)
							stack_ids[#stack_ids + 1] = buff_id
						end
					elseif num_chunks < num_buff_stacks then
						local difference = num_buff_stacks - num_chunks
						local stack_ids = buff.stack_ids[unit]

						for i = 1, difference, 1 do
							local buff_id = table.remove(stack_ids)

							buff_system:remove_server_controlled_buff(unit, buff_id)
						end
					end
				end
			end
		end
	end
)
