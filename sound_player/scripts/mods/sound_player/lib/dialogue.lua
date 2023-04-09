--[[---------------------------------------------------------------------------------------------------------
    DESCRIPTION: Class for storing and searching in a dialogue list.
         AUTHOR: Zaphio
--]]
---------------------------------------------------------------------------------------------------------
local mod = get_mod("sound_player")
local Dialogue = class()

local noop = function() end

function Dialogue:init()
	-- Dummy environment to load stuff
	self._dialogue_file_env = {
		OP = TagQuery.OP,
		define_rule = noop,
		add_dialogues = callback(self, "cb_add_from_list"),
	}
end

function Dialogue:cb_add_from_list(dialogues)
	for name, dialogue in pairs(dialogues) do
		dialogue.category = dialogue.category or "default"
		for i = 1, dialogue.sound_events_n do
			self:add_dialogue(dialogue.sound_events[i], dialogue.localization_strings[i])
		end
	end
end

local initials_to_char = {
	-- Enemies
	ect = "Skaven Champion",
	egs = "Grey Seer",
	ebh = "Boss Halescourge",
	ecc = "Chaos Champion",
	ecw = "Chaos Warrior",
	ecr = "Clan Rat",
	esv = "Storm Vermin",
	epm = "Pack Master",
	esr = "Skaven Ratling",
	ecm = "Chaos Mauler",
	epwg = "Poison Wind Globadier",
	-- NPCs
	nde = "Dwarf Engineer",
	nfl = "Ferry Lady",
	nik = "Inn Keeper",
	ntw = "Grey Wizard",
	-- Players
	pbw = "Bright Wizard",
	pdr = "Dwarf Ranger",
	pes = "Empire Soldier",
	pwe = "Wood Elf",
	pwh = "Witch Hunter",
}

function Dialogue:add_dialogue(wwise_event, subtitle_localization_id)
	local data = {
		event = wwise_event,
		subtitle = Localize(subtitle_localization_id),
		utility = 0,
		character = character,
		format = {
			1,
			Colors.color_definitions.silver,
			1,
			Colors.color_definitions.white,
		},
	}

	local character = initials_to_char[string.sub(wwise_event, 1, 3)]
	if character then
		data.subtitle = character .. ": " .. data.subtitle
		data.format[3] = #character + 2
	end

	self[#self + 1] = data
end

function Dialogue:load_from_file(file_path)
	if not Application.can_get("lua", file_path) then
		return
	end

	local loader_thunk = mod:dofile(file_path)
	if not loader_thunk then
		return
	end

	return mod:pcall(setfenv(loader_thunk, self._dialogue_file_env))
end

function Dialogue:load_from_file_list(dialogue_file_list)
	for _, dialogue_file in ipairs(dialogue_file_list) do
		self:load_from_file(dialogue_file)
	end
end

function Dialogue:perform_search(needle_list)
	local last_insert = 1
	for i, data in ipairs(self) do
		local subtitle = string.lower(data.subtitle)
		local utility = 0

		local fi = data.format_index
		local format, format_n, init = data.format, 4
		local init = data.format[3] -- Kludge. The index in which the text begins.
		for _, needle in ipairs(needle_list) do
			local a, b = string.find(subtitle, needle, init, true)
			if a then
				format[format_n + 1], format[format_n + 2] = a, Colors.color_definitions.steel_blue
				format[format_n + 3], format[format_n + 4] = b + 1, Colors.color_definitions.white
				init = b + 1
				utility = utility + 1
				format_n = format_n + 4
			end
		end
		data.utility = utility
		for j = format_n + 1, #format do
			format[j] = nil
		end
		if utility ~= 0 then
			-- Insert sort.
			local j = last_insert
			while j >= 2 and utility > self[j - 1].utility do
				j = j - 1
			end
			self[i], self[j] = self[j], self[i]
			last_insert = last_insert + 1
		end
	end
end

return Dialogue
