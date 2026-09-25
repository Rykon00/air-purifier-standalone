-- Absorbs pollution around each working air purifier.
-- Area: every chunk whose center lies within RADIUS tiles of the purifier (own chunk always included).
local NAME = "kr-air-purifier"
local INTERVAL = 60 -- every purifier is processed once per INTERVAL ticks
local RADIUS = settings.startup["aps-radius"].value

local function chunk_targets(pos)
  local cx, cy = math.floor(pos.x / 32), math.floor(pos.y / 32)
  local targets = { { cx * 32 + 16, cy * 32 + 16 } }
  local n = math.ceil(RADIUS / 32) + 1
  local r2 = RADIUS * RADIUS
  for dx = -n, n do
    for dy = -n, n do
      if dx ~= 0 or dy ~= 0 then
        local x, y = (cx + dx) * 32 + 16, (cy + dy) * 32 + 16
        local ddx, ddy = x - pos.x, y - pos.y
        if ddx * ddx + ddy * ddy <= r2 then targets[#targets + 1] = { x, y } end
      end
    end
  end
  return targets
end

local function register(entity)
  if entity and entity.valid and entity.name == NAME then
    storage.purifiers[entity.unit_number] = { entity = entity, targets = chunk_targets(entity.position) }
  end
end

local function rescan()
  storage.purifiers = {}
  storage.cursor = nil
  for _, surface in pairs(game.surfaces) do
    for _, e in pairs(surface.find_entities_filtered({ name = NAME })) do register(e) end
  end
end

local status_factor = {
  [defines.entity_status.working] = 1,
  [defines.entity_status.low_power] = 0.5,
}

local function absorb(data)
  local entity = data.entity
  local factor = status_factor[entity.status]
  if not factor then return end
  local amount = settings.global["aps-absorption"].value * INTERVAL / 3600 * factor
  local surface = entity.surface
  local targets = data.targets

  local chunks, total = {}, 0
  for i = 1, #targets do
    local p = targets[i]
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

local function on_tick()
  local list = storage.purifiers
  local count = table_size(list)
  if count == 0 then return end
  local per_tick = math.ceil(count / INTERVAL)
  local key = storage.cursor
  if key ~= nil and list[key] == nil then key = nil end
  for _ = 1, per_tick do
    local data
    key, data = next(list, key)
    if key == nil then break end
    if data.entity.valid then
      absorb(data)
    else
      list[key] = nil
    end
  end
  storage.cursor = key
end

script.on_init(rescan)
script.on_configuration_changed(rescan)

local filter = { { filter = "name", name = NAME } }
local function on_built(event) register(event.entity or event.destination) end
script.on_event(defines.events.on_built_entity, on_built, filter)
script.on_event(defines.events.on_robot_built_entity, on_built, filter)
script.on_event(defines.events.script_raised_built, on_built, filter)
script.on_event(defines.events.script_raised_revive, on_built, filter)
script.on_event(defines.events.on_entity_cloned, on_built, filter)

script.on_event(defines.events.on_tick, on_tick)
