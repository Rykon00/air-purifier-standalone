-- Functional test for air-purifier-standalone, run by tools/load_check.py --test-mod tests/functional-test.
-- Three polluted chunks far apart, on lab tiles (no natural absorption) and with pollution diffusion off:
-- one with 10 powered purifiers with filters, one with 10 purifiers without filters, one with nothing.
-- Only the first may lose pollution (default absorption 50/min per purifier).
-- Writes "[functional-test] PASS|FAIL ..." and ends with DONE.

local TAG = "[functional-test] "
local START = 10
local CHECK = START + 3000
local PURIFIERS = 10
local POLLUTION = 20000

local s_expected = 0

local function pass(msg) log(TAG .. "PASS " .. msg) end
local function fail(msg) log(TAG .. "FAIL " .. msg) end

local spots = {
  {label = "purifier with filter", x = 0, purifier = true, filter = true},
  {label = "purifier without filter", x = 2048, purifier = true, filter = false},
  {label = "no purifier", x = -2048, purifier = false},
}

local function setup()
  local surface = game.surfaces[1]
  local force = game.forces.player
  game.map_settings.pollution.enabled = true
  game.map_settings.pollution.diffusion_ratio = 0
  force.technologies["kr-air-purification"].researched = true
  local per_min = settings.global["aps-absorption"].value

  for _, s in ipairs(spots) do
    surface.request_to_generate_chunks({s.x + 16, 16}, 3)
  end
  surface.force_generate_chunk_requests()

  for _, s in ipairs(spots) do
    local area = {{s.x, 0}, {s.x + 32, 32}}
    for _, e in pairs(surface.find_entities_filtered{area = area}) do
      if e.valid and e.type ~= "character" then e.destroy() end
    end
    local tiles = {}
    for x = s.x, s.x + 31 do for y = 0, 31 do tiles[#tiles + 1] = {name = "lab-dark-1", position = {x, y}} end end
    surface.set_tiles(tiles)
    local center = {s.x + 16, 16}
    if s.purifier then
      local eei = surface.create_entity{name = "electric-energy-interface", position = {s.x + 16, 16}, force = force}
      eei.electric_buffer_size = 1e10
      eei.power_production = 1e9
      eei.energy = 1e10
      surface.create_entity{name = "substation", position = {s.x + 16, 19}, force = force}
      for i = 1, PURIFIERS do
        local p = surface.create_entity{name = "kr-air-purifier", position = {s.x + 7.5 + (i - 1) * 2, 24},
                                        force = force, raise_built = true}
        if s.filter then p.insert{name = "kr-pollution-filter", count = 5} end
        s.entity = p
      end
    end
    surface.pollute(center, POLLUTION)
    s.before = surface.get_pollution(center)
  end
  s_expected = PURIFIERS * per_min * (CHECK - START) / 3600
end

local function check()
  local surface = game.surfaces[1]
  for _, s in ipairs(spots) do
    s.drop = s.before - surface.get_pollution({s.x + 16, 16})
  end
  local bare = spots[3].drop
  local with, without = spots[1], spots[2]
  -- expected: PURIFIERS * absorption per minute * minutes (all from the own chunk, nothing diffuses)
  if with.drop - bare > 0.6 * s_expected then
    pass(string.format("%s: removed %.0f (bare spot %.0f, expected about %.0f)", with.label, with.drop, bare, s_expected))
  else
    fail(string.format("%s: removed only %.0f (bare spot %.0f, expected about %.0f)", with.label, with.drop, bare, s_expected))
  end
  if math.abs(without.drop - bare) < 0.05 * s_expected then
    pass(string.format("%s: no absorption (%.0f vs %.0f)", without.label, without.drop, bare))
  else
    fail(string.format("%s: absorbed although it has no filter (%.0f vs %.0f)", without.label, without.drop, bare))
  end
  log(TAG .. "DONE")
end

script.on_nth_tick(START, function(e) if e.tick == START then setup() end end)
script.on_nth_tick(CHECK, function(e) if e.tick == CHECK then check() end end)
