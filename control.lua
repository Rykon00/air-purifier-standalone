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

-- per-player visibility of the map circles (storage.map_on[player_index] = true)
local function visible_players()
  local list = {}
  for index, on in pairs(storage.map_on) do
    local player = game.get_player(index)
    if on and player and player.valid then list[#list + 1] = player end
  end
  return list
end

local function apply_visibility(objects, list)
  for _, obj in pairs(objects) do
    if obj.valid then
      if #list == 0 then
        obj.visible = false
      else
        obj.players = list
        obj.visible = true
      end
    end
  end
end

local function draw_map_radius(entity, list)
  local r = math.max(RADIUS, 1)
  local objects = {
    rendering.draw_circle({
      target = entity, surface = entity.surface, radius = r, render_mode = "chart",
      color = { 0.1, 0.35, 0.18, 0.15 }, filled = true, draw_on_ground = true,
    }),
    rendering.draw_circle({
      target = entity, surface = entity.surface, radius = r, render_mode = "chart",
      color = { 0.35, 1, 0.55, 0.9 }, width = 2,
    }),
  }
  apply_visibility(objects, list or visible_players())
  return objects
end

local function refresh_visibility()
  local list = visible_players()
  for _, data in pairs(storage.purifiers) do apply_visibility(data.renders, list) end
end

local function register(entity)
  if entity and entity.valid and entity.name == NAME then
    storage.purifiers[entity.unit_number] = {
      entity = entity,
      targets = chunk_targets(entity.position),
      renders = draw_map_radius(entity),
    }
  end
end

local function init_players()
  storage.map_on = storage.map_on or {}
  for _, player in pairs(game.players) do
    if storage.map_on[player.index] == nil then storage.map_on[player.index] = true end
    player.set_shortcut_toggled("aps-toggle-map-radius", storage.map_on[player.index])
  end
end

local function rescan()
  init_players()
  rendering.clear(script.mod_name)
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

local function toggle(player_index)
  local player = game.get_player(player_index)
  if not player then return end
  local on = not storage.map_on[player_index]
  storage.map_on[player_index] = on
  player.set_shortcut_toggled("aps-toggle-map-radius", on)
  refresh_visibility()
end

script.on_event("aps-toggle-map-radius", function(event) toggle(event.player_index) end)
script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == "aps-toggle-map-radius" then toggle(event.player_index) end
end)
script.on_event(defines.events.on_player_created, function(event)
  storage.map_on[event.player_index] = true
  local player = game.get_player(event.player_index)
  player.set_shortcut_toggled("aps-toggle-map-radius", true)
  refresh_visibility()
end)

local filter = { { filter = "name", name = NAME } }
local function on_built(event) register(event.entity or event.destination) end
script.on_event(defines.events.on_built_entity, on_built, filter)
script.on_event(defines.events.on_robot_built_entity, on_built, filter)
script.on_event(defines.events.script_raised_built, on_built, filter)
script.on_event(defines.events.script_raised_revive, on_built, filter)
script.on_event(defines.events.on_entity_cloned, on_built, filter)

script.on_event(defines.events.on_tick, on_tick)
