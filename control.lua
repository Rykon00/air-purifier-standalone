-- Absorbs pollution around each working air purifier in a configurable chunk radius.
local NAME = "kr-air-purifier"
local INTERVAL = 60 -- every purifier is processed once per INTERVAL ticks

local offsets -- list of {dx, dy} chunk offsets inside the circular radius
local function build_offsets()
  local r = settings.global["aps-radius"].value
  offsets = {}
  for dx = -r, r do
    for dy = -r, r do
      if dx * dx + dy * dy <= r * r + r then offsets[#offsets + 1] = { dx, dy } end
    end
  end
end

local function register(entity)
  if entity and entity.valid and entity.name == NAME then
    storage.purifiers[entity.unit_number] = entity
  end
end

local function rescan()
  storage.purifiers = {}
  for _, surface in pairs(game.surfaces) do
    for _, e in pairs(surface.find_entities_filtered({ name = NAME })) do register(e) end
  end
end

local status_factor = {
  [defines.entity_status.working] = 1,
  [defines.entity_status.low_power] = 0.5,
}

local function absorb(entity)
  local factor = status_factor[entity.status]
  if not factor then return end
  local amount = settings.global["aps-absorption"].value * INTERVAL / 3600 * factor
  local surface = entity.surface
  local pos = entity.position
  local cx, cy = math.floor(pos.x / 32), math.floor(pos.y / 32)

  local chunks, total = {}, 0
  for i = 1, #offsets do
    local o = offsets[i]
    local p = { (cx + o[1]) * 32 + 16, (cy + o[2]) * 32 + 16 }
    local pol = surface.get_pollution(p)
    if pol > 0 then
      chunks[#chunks + 1] = { p, pol }
      total = total + pol
    end
  end
  if total <= 0 then return end

  -- take proportionally to each chunk's pollution (dirtiest chunks are cleaned fastest)
  local ratio = math.min(1, amount / total)
  for i = 1, #chunks do
    surface.pollute(chunks[i][1], -chunks[i][2] * ratio)
  end
end

local function on_tick(event)
  local list = storage.purifiers
  local count = table_size(list)
  if count == 0 then return end
  local per_tick = math.ceil(count / INTERVAL)
  local key = storage.cursor
  if key ~= nil and list[key] == nil then key = nil end
  for _ = 1, per_tick do
    local entity
    key, entity = next(list, key)
    if key == nil then break end
    if entity.valid then
      absorb(entity)
    else
      list[key] = nil
    end
  end
  storage.cursor = key
end

script.on_init(function()
  build_offsets()
  rescan()
end)
script.on_configuration_changed(function()
  build_offsets()
  rescan()
end)
script.on_load(build_offsets)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "aps-radius" then build_offsets() end
end)

local filter = { { filter = "name", name = NAME } }
local function on_built(event) register(event.entity or event.destination) end
script.on_event(defines.events.on_built_entity, on_built, filter)
script.on_event(defines.events.on_robot_built_entity, on_built, filter)
script.on_event(defines.events.script_raised_built, on_built, filter)
script.on_event(defines.events.script_raised_revive, on_built, filter)
script.on_event(defines.events.on_entity_cloned, on_built, filter)

script.on_event(defines.events.on_tick, on_tick)
