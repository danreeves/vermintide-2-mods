-- luacheck: globals get_mod table.merge NetworkLookup
local mod = get_mod("MutatorUnstableTeleport")

mod.templates = {}

local template_file = "scripts/settings/mutator_settings"

mod:hook(_G, "local_require", function(func, path, ...)
	if path == template_file then
		local templates = func(path)
		return table.merge(templates, mod.templates)
	end
	return func(path, ...)
end)

function mod.add_mutator_template(name, template)
	mod.templates[name] = template

	mod:dofile("scripts/managers/game_mode/mutator_templates")

	local network_id = rawget(NetworkLookup.mutator_templates, name)

	if network_id == nil then
		network_id = #NetworkLookup.mutator_templates + 1
	end

	NetworkLookup.mutator_templates[network_id] = name
	NetworkLookup.mutator_templates[name] = network_id
end
