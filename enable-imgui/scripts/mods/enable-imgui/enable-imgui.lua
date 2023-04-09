local mod = get_mod("enable-imgui")
-- local moreitemslibrary = get_mod("MoreItemsLibrary")

function mod.on_all_mods_loaded()
	Managers.package:load("resource_packages/imgui/imgui", "raindish-mod", function()
		mod:dofile("scripts/imgui/imgui")
		-- mod:dofile("scripts/imgui/imgui_ui_editor") -- TODO

		ImguiManager.init = function(self)
			self._open = false
			self._persistant_windows = 0
			self._guis = {}
			self._key_bindings = {}

			self:add_gui(ImguiUIEditor, "Tools", "Texture Explorer") -- TODO
			self:add_gui(ImguiUmbraDebug, "World", "Umbra")
			self:add_gui(ImguiCombatLog, "Gameplay", "Combat Log")
			self:add_gui(ImguiCraftItem, "Gameplay", "Craft Item")
			self:add_gui(ImguiWeaponDebug, "Gameplay", "Weapon Debug")
			self:add_gui(ImguiBuffsDebug, "Gameplay", "Buffs Debug")
			self:add_gui(ImguiAISpawnLog, "Gameplay", "AI Spawn Log")
			self:add_gui(ImguiTeleportTool, "Gameplay", "Teleport Tool")
			self:add_gui(ImguiBehaviorTree, "Gameplay", "BT Debug")
			self:add_gui(ImguiTerrorEventDebug, "Gameplay", "Terror Event Debug")
			self:add_gui(ImguiSpawning, "Gameplay", "Spawn Breeds/Pickups")
			self:add_gui(ImguiDebugMenu, "Debug", "Debug Menu 2.0")
			self:add_gui(ImguiUnlockOverride, "Debug", "Unlock Override")
			self:add_gui(ImguiLocalization, "Tools", "Localization")
			self:add_gui(ImguiCombatLog, "Gameplay", "Combat Log")
			self:add_gui(ImguiCraftItem, "Gameplay", "Craft Item")
			self:add_gui(ImguiWeaponDebug, "Gameplay", "Weapon Debug")
			self:add_gui(ImguiBuffsDebug, "Gameplay", "Buffs Debug")
			self:add_gui(ImguiAISpawnLog, "Gameplay", "AI Spawn Log")
			self:add_gui(ImguiTeleportTool, "Gameplay", "Teleport Tool")
			self:add_gui(ImguiBehaviorTree, "Gameplay", "BT Debug")
			-- self:add_gui(ImguiServerBrowser, "Gameplay", "Server Browser")
			self:add_gui(ImguiTerrorEventDebug, "Gameplay", "Terror Event Debug")
			self:add_gui(ImguiSpawning, "Gameplay", "Spawn Breeds/Pickups")
			self:add_gui(ImguiSoundDebug, "Gameplay", "Sound Debug")
			self:add_gui(ImguiCareerDebug, "Gameplay", "Career Debug")
			self:add_gui(ImguiLocalization, "Tools", "Localization")
			self:add_gui(ImguiDebugMenu, "Debug", "Debug Menu 2.0")
			self:add_gui(ImguiUnlockOverride, "Debug", "Unlock Override")
			self:add_gui(ImguiCallInterceptor, "Debug", "Call Interceptor")

			if PLATFORM == "win32" then
				self:add_gui(ImguiLuaScratchpad, "Debug", "Lua Scratchpad")
				self:add_gui(ImguiJIT, "Debug", "JIT Debug")
				self:add_gui(ImguiFlamegraph, "Debug", "Flamegraph")
			end

			local mechanism_key = Managers.mechanism:current_mechanism_name()

			if mechanism_key == "versus" then
			end

			-- for _, dlc in pairs(DLCSettings) do
			--   local imgui_system_params = dlc.imgui_system_params or {}
			--
			--   for _, params in pairs(imgui_system_params) do
			--     require(params.require)
			--
			--     local gui_class = rawget(_G, params.gui)
			--     local category = params.category
			--     local name = params.name
			--     local enabled = params.enabled
			--
			--     self:add_gui(gui_class:new(), category, name, enabled)
			--   end
			-- end

			self:_load_settings()
		end

		mod.imgui_manager = ImguiManager:new()
		Imgui.open_imgui()
		-- Imgui.enable_imgui_input_system(Imgui.KEYBOARD)
		-- Imgui.enable_imgui_input_system(Imgui.MOUSE)
	end, true, true)
end

function mod.update()
	if mod.imgui_manager then
		mod.imgui_manager:update()
	end
	if not mod.load_imgui_called then
		mod.load_imgui()
	end
end

--[[
mod:hook_safe(IngameHud, "init", function()
  mod.imgui_manager = ImguiManager:new()
end)

mod:hook_safe(IngameHud, "update", function()
  if mod.imgui_manager then
	mod.imgui_manager:update()
  end
end)

function mod.on_enabled()
  mod.imgui_manager = ImguiManager:new()
end

mod:hook(ImguiCraftItem, 'give_item', function(func, self, item_key, power_level, skin_name, rarity, properties, traits)
  mod:echo(item_key .. rarity)
  local traits_list = {}
  for trait,_ in pairs(traits) do
	table.insert(traits_list, trait)
  end
  local entry = table.clone(ItemMasterList[item_key])
  local backend_id = string.format("imgui-craft-item %d", math.random(10000))
  entry.mod_data = {
	backend_id = backend_id,
	ItemInstanceId = backend_id,
	CustomData = {
	  traits = cjson.encode(traits_list),
	  power_level = string.format("%d", power_level),
	  properties = cjson.encode(properties),
	  rarity = rarity,
	},
	traits = traits_list,
	power_level = power_level,
	properties = properties,
	rarity = rarity,
  }

  if skin_name then
	entry.mod_data.CustomData.skin = skin_name
	entry.mod_data.skin = skin_name
	entry.mod_data.inventory_icon = WeaponSkins.skins[skin_name].inventory_icon
  end

  moreitemslibrary:add_mod_items_to_local_backend({entry}, "enable-imgui")

  local backend_items = Managers.backend:get_interface("items")
  local new_item = backend_items:get_item_from_id(backend_id)

  if rarity then
	new_item.rarity = rarity
	new_item.data.rarity = rarity
	new_item.CustomData.rarity = rarity
  end

  ItemHelper.mark_backend_id_as_new(backend_id)

  if mod.inventory_ui then
	backend_items:_refresh()
	local inv_item_grid = mod.inventory_ui._item_grid
	local index = inv_item_grid._selected_page_index
	local settings = inv_item_grid._category_settings[index]
	local item_filter = settings.item_filter
	inv_item_grid:change_item_filter(item_filter, false)
	inv_item_grid:repopulate_current_inventory_page()
  end
end)

mod.inventory_ui = nil

mod:hook_safe(HeroWindowLoadoutInventory, "on_enter", function(self)
  mod.inventory_ui = self
end)

mod:hook_safe(HeroWindowLoadoutInventory, "on_exit", function(self)
  mod.inventory_ui = nil
end)

]]
--
