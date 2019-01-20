local mod = get_mod("lumberfoots")

-- Everything here is optional. You can remove unused parts.
return {
	name = "Handmaiden has a limited vocabulary",   -- Readable mod name
	description = mod:localize("mod_description"),  -- Mod description
	is_togglable = false,                            -- If the mod can be enabled/disabled
	is_mutator = false,                             -- If the mod is mutator
}