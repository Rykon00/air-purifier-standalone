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

-- Map display: the union of all cleaned chunks is drawn once per chunk (no stacking).
-- storage.cover[surface_index][chunk_key] = { count = n, obj = LuaRenderObject }
-- storage.map_on[player_index] = true -> player sees the chunks on the map

local COLOR = { 0.08, 0.30, 0.15, 0.30 }

local function visible_players()
  local list = {}
  for index, on in pairs(storage.map_on) do
    local player = game.get_player(index)
    if on and player and player.valid then list[#list + 1] = player end
  end
  return list
end

local function apply_visibility(obj, list)
  if not (obj and obj.valid) then return end
  if #list == 0 then
    obj.visible = false
  else
    obj.players = list
    obj.visible = true
  end
end

local function refresh_visibility()
  local list = visible_players()
  for _, chunks in pairs(storage.cover) do
    for _, c in pairs(chunks) do apply_visibility(c.obj, list) end
  end
end

local function chunk_key(p) return (p[1] - 16) / 32 .. "," .. (p[2] - 16) / 32 end

local function add_cover(surface, targets)
  local chunks = storage.cover[surface.index]
  if not chunks then
    chunks = {}
    storage.cover[surface.index] = chunks
  end
  local list
  for _, p in pairs(targets) do
    local key = chunk_key(p)
    local c = chunks[key]
    if c then
      c.count = c.count + 1
    else
      list = list or visible_players()
      local obj = rendering.draw_rectangle({
        surface = surface,
        left_top = { p[1] - 16, p[2] - 16 },
        right_bottom = { p[1] + 16, p[2] + 16 },
        color = COLOR, filled = true, render_mode = "chart",
      })
      apply_visibility(obj, list)
      chunks[key] = { count = 1, obj = obj }
    end
  end
end

local function remove_cover(surface_index, targets)
  local chunks = storage.cover[surface_index]
  if not chunks then return end
  for _, p in pairs(targets) do
    local key = chunk_key(p)
    local c = chunks[key]
    if c then
      c.count = c.count - 1
      if c.count <= 0 then
        if c.obj and c.obj.valid then c.obj.destroy() end
        chunks[key] = nil
      end
    end
  end
end

local function register(entity)
  if entity and entity.valid and entity.name == NAME and not storage.purifiers[entity.unit_number] then
    local targets = chunk_targets(entity.position)
    storage.purifiers[entity.unit_number] = {
      entity = entity,
      surface_index = entity.surface.index,
      targets = targets,
    }
    add_cover(entity.surface, targets)
  end
end

local function unregister(unit_number)
  local data = storage.purifiers[unit_number]
  if not data then return end
  storage.purifiers[unit_number] = nil
  remove_cover(data.surface_index, data.targets)
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
  storage.cover = {}
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
      unregister(key)
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

local function on_removed(event)
  local entity = event.entity
  if entity and entity.valid and entity.unit_number then unregister(entity.unit_number) end
end
script.on_event(defines.events.on_player_mined_entity, on_removed, filter)
script.on_event(defines.events.on_robot_mined_entity, on_removed, filter)
script.on_event(defines.events.on_entity_died, on_removed, filter)
script.on_event(defines.events.script_raised_destroy, on_removed, filter)

script.on_event(defines.events.on_tick, on_tick)
