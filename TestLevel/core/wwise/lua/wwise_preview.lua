-- Works with the Editor to play & stop events in one or more banks,
-- to allow the user to preview bank content in the editor.

stingray.WwisePreview = stingray.WwisePreview or {}
local WwisePreview = stingray.WwisePreview

local Application = stingray.Application
local Wwise = stingray.Wwise
local WwiseWorld = stingray.WwiseWorld

WwisePreview.active_banks = WwisePreview.active_banks or {}

-- Will load the bank if it has not been loaded by WwisePreview yet, then trigger the given event.
-- If the given event is already playing, it will stop and restart it.
function WwisePreview.play_event(world, bank_resource_name, event_name)
	if not Wwise then
		return
	end

	-- Get bank info and load bank if not loaded
	local active_banks = WwisePreview.active_banks
	local active_bank = active_banks[bank_resource_name]
	if not active_bank then
		active_bank = { name = bank_resource_name, active_events = {} }
		active_banks[bank_resource_name] = active_bank
		Wwise.load_bank(bank_resource_name)
	end

	-- Stop the event if it is already playing, if not prepare it.
	local active_events = active_bank.active_events
	local active_event = active_events[event_name]
	local wwise_world = Wwise.wwise_world(world)
	if active_event then
		WwiseWorld.stop_event(wwise_world, active_event.playing_id)
	else
		active_event = {}
		active_events[event_name] = active_event
	end

	-- Play the sound
	active_event.playing_id = WwiseWorld.trigger_event(wwise_world, event_name)
end

-- Should only be called if no events are actively playing, e.g. by calling
-- WwisePreview.stop_all_events beforehand.
function WwisePreview.unload_bank(bank_resource_name)
	if not Wwise then
		return
	end

	Wwise.unload_bank(bank_resource_name)
end

function WwisePreview.stop_event(world, bank_resource_name, event_name)
	if not Wwise then
		return
	end

	local active_bank = WwisePreview.active_banks[bank_resource_name]
	if active_bank then
		local active_events = active_bank.active_events
		local active_event = active_events[event_name]
		if active_event then
			local wwise_world = Wwise.wwise_world(world)
			WwiseWorld.stop_event(wwise_world, active_event.playing_id)
			active_events[event_name] = nil
		else
			print("Warning: WwisePreview.stop_active_event event ", event_name, "is not active.")
		end
	else
		print("Warning: WwisePreview.stop_active_event bank", bank_resource_name, "has no active events to stop.")
	end
end

local function notify_editor_event_finished(bank, event)
	Application.console_send({
		type = "wwise_event_finished",
		bank_resource_name = bank,
		event_name = event,
	})
end

function WwisePreview.stop_all_events(world, should_notify_editor)
	if not Wwise then
		return
	end

	local wwise_world = Wwise.wwise_world(world)
	local active_banks = WwisePreview.active_banks
	for bank_resource_name, active_bank in pairs(active_banks) do
		local active_events = active_bank.active_events
		for event_name, info in pairs(active_events) do
			WwiseWorld.stop_event(wwise_world, info.playing_id)
			if should_notify_editor == true then
				notify_editor_event_finished(bank_resource_name, event_name)
			end
		end
	end
	WwisePreview.active_banks = {}
end

function WwisePreview.update(world)
	if not Wwise then
		return
	end

	-- Go through active sounds and handle if any are finished playing.
	local wwise_world = Wwise.wwise_world(world)
	local active_banks = WwisePreview.active_banks
	for bank_resource_name, active_bank in pairs(active_banks) do
		local active_event_count = 0
		local active_events = active_bank.active_events
		for event_name, info in pairs(active_events) do
			if not WwiseWorld.is_playing(wwise_world, info.playing_id) then
				notify_editor_event_finished(bank_resource_name, event_name)
				active_events.event_name = nil
			else
				active_event_count = active_event_count + 1
			end
		end -- for each active event
		if active_event_count == 0 then
			-- Note potentially sketchy interaction here! If another Wwise system
			-- in the editor has loaded this bank and we now unload it, events may
			-- fail to play! Currently nothing does this but we would need to create
			-- a bank manager to track bank usage if the need arises.
			Wwise.unload_bank(bank_resource_name)
			active_banks[bank_resource_name] = nil
		end
	end -- for each active bank
end

return WwisePreview
