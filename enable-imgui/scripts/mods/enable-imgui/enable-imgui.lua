local mod = get_mod("enable-imgui")

-- Copied from source because I couldn't figure out how to require them
-- or load the correct resource
ImguiManager = mod:dofile("scripts/mods/enable-imgui/imgui/imgui")

mod:hook_safe(IngameHud, "init", function()
  mod.imgui_manager = ImguiManager:new()
end)

mod:hook_safe(IngameHud, "update", function()
  mod.imgui_manager:update()
end)

function mod.on_enabled()
  mod.imgui_manager = ImguiManager:new()
end
