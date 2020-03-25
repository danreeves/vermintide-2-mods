local mod = get_mod("store-improvements")
local initialised = false

mod:dofile("scripts/mods/store-improvements/ui/ui")

-- We need to set up hooks when the game is more initialised than the
-- usual time mods are initialised
mod:hook_safe(HeroView, 'init', function(self)
  mod.wwise_world = self.wwise_world
  if not initialised then
    initialised = true
    enable_hooks()
  end
end)

mod:hook_safe(HeroView, 'update', function(self)
  mod.wwise_world = self.wwise_world
  if not initialised then
    initialised = true
    enable_hooks()
  end
end)

function enable_hooks()
  mod:hook(BackendInterfacePeddlerPlayFab, "get_peddler_stock", function(func, self)
    local items = func(self)
    return maybe_filter_items(items)
  end)

  mod:hook(BackendInterfacePeddlerPlayFab, "get_filtered_items", function(func, self, filter, params)
    local items = func(self, filter, params)
    return maybe_filter_items(items)
  end)

  mod:hook(StoreWindowPanel, 'on_enter', function(func, self, params, offset)
    mod.store_improvements_ui = StoreImprovementsUI:new(params)
    func(self, params, offset)
  end)

  mod:hook(StoreWindowPanel, 'update', function(func, self, dt, t)
    if mod.store_improvements_ui then
      mod.store_improvements_ui:update(dt)
    end
    func(self, dt, t)
  end)

  mod:hook(StoreWindowPanel, 'on_exit', function(func, ...)
    if mod.store_improvements_ui then
      mod.store_improvements_ui:destroy()
      mod.store_improvements_ui = nil
    end
    func(...)
  end)

  mod:hook_safe(HeroViewStateStore, "on_enter", function(self)
    mod.store_state = self
  end)
end

function mod.on_setting_changed(setting_id)
  if mod.store_state then
    local current_path = mod.store_state:get_store_path()
    mod.store_state:go_to_store_path(current_path)
  end
end


--[[ FILTERS ]]--
function filter_owned(items)
  local backend_items = Managers.backend:get_interface("items")
  local filtered_items = {}
  for _, item in pairs(items) do
    local is_owned = backend_items:has_item(item.key) or
      backend_items:has_weapon_illusion(item.key)
    if is_owned == false then
      table.insert(filtered_items, item)
    end
  end
  return filtered_items
end

function filter_affordable(items)
  local backend_store = Managers.backend:get_interface("peddler")
  local currency_amount = backend_store:get_chips("SM")
  local filtered_items = {}
  for _, item in pairs(items) do
    local can_afford = false
    if item.data.rarity == "promo" then
      can_afford = true
    else
      can_afford = item.current_prices.SM <= currency_amount
    end
    if can_afford then
      table.insert(filtered_items, item)
    end
  end
  return filtered_items
end

function maybe_filter_items(items)
  local filters = {}
  local items = items
  if mod:get("filter_owned") then
    table.insert(filters, filter_owned)
  end
  if mod:get("filter_affordable") then
    table.insert(filters, filter_affordable)
  end
  for _, filter in pairs(filters) do
    items = filter(items)
  end
  return items
end

