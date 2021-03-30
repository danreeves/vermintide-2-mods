-- luacheck: globals get_mod Breeds NetworkLookup BreedActions
local mod = get_mod("Badgers")

local function add_to_networklookup(table_name, new_key)
	local new_id = #NetworkLookup[table_name] + 1
	NetworkLookup[table_name][new_id] = new_key
	NetworkLookup[table_name][new_key] = new_id
end

Breeds.critter_pig.base_unit = "units/Badger/Badger"
Breeds.critter_pig.hit_zones = {
	full = {
		prio = 1,
		actors = {
			"Badger"
		}
	}
}
BreedActions.critter_pig = {
	idle = {
		anim_event = "idle",
	}
}

add_to_networklookup("husks", "units/Badger/Badger")

mod:echo("Badgers enabled!")
