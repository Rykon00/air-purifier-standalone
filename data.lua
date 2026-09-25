-- Graphics/sound: Krastorio2Assets (LGPL-3.0 / sounds MIT).
-- Derived from Krastorio 2 (https://codeberg.org/raiguard/Krastorio2), LGPL-3.0.
-- Prototype names keep the "kr-" prefix so kr-air-purifier-helper works with this mod.
local hit_effects = require("__base__.prototypes.entity.hit-effects")
local sounds = require("__base__.prototypes.entity.sounds")
local A = "__air-purifier-standalone__"

local connector = {
  variation = 30,
  main_offset = util.by_pixel_hr(0, 40),
  shadow_offset = util.by_pixel_hr(-5, 35),
  show_shadow = false,
}

data:extend({
  { type = "recipe-category", name = "kr-air-purification" },

  -- Items
  {
    type = "item",
    name = "kr-air-purifier",
    icon = A .. "/graphics/icons/air-purifier.png",
    subgroup = "production-machine",
    order = "z[air-purifier]",
    place_result = "kr-air-purifier",
    stack_size = 50,
  },
  {
    type = "item",
    name = "kr-pollution-filter",
    icon = A .. "/graphics/icons/pollution-filter.png",
    subgroup = "intermediate-product",
    order = "w2-a1[pollution-filter]",
    stack_size = 50,
  },
  {
    type = "item",
    name = "kr-used-pollution-filter",
    icon = A .. "/graphics/icons/used-pollution-filter.png",
    subgroup = "intermediate-product",
    order = "w2-a2[used-pollution-filter]",
    stack_size = 50,
  },

  -- Recipes
  {
    type = "recipe",
    name = "kr-air-purifier",
    energy_required = 5,
    enabled = false,
    ingredients = {
      { type = "item", name = "steel-plate", amount = 10 },
      { type = "item", name = "advanced-circuit", amount = 4 },
      { type = "item", name = "plastic-bar", amount = 20 },
      { type = "item", name = "engine-unit", amount = 1 },
    },
    results = { { type = "item", name = "kr-air-purifier", amount = 1 } },
  },
  {
    type = "recipe",
    name = "kr-pollution-filter",
    category = "chemistry",
    enabled = false,
    energy_required = 10,
    ingredients = {
      { type = "item", name = "steel-plate", amount = 2 },
      { type = "item", name = "plastic-bar", amount = 2 },
      { type = "item", name = "coal", amount = 5 },
    },
    results = { { type = "item", name = "kr-pollution-filter", amount = 1 } },
    allow_productivity = true,
  },
  {
    type = "recipe",
    name = "kr-restore-used-pollution-filter",
    icon = A .. "/graphics/icons/restore-used-pollution-filter.png",
    icon_size = 128,
    subgroup = "intermediate-product",
    order = "w3-a[restore-used-pollution-filter]",
    category = "chemistry",
    enabled = false,
    energy_required = 10,
    ingredients = {
      { type = "item", name = "kr-used-pollution-filter", amount = 1 },
      { type = "item", name = "coal", amount = 2 },
      { type = "fluid", name = "water", amount = 50 },
    },
    results = { { type = "item", name = "kr-pollution-filter", amount = 1 } },
    auto_recycle = false,
  },
  {
    type = "recipe",
    name = "kr-air-cleaning",
    icon = A .. "/graphics/icons/filtering.png",
    subgroup = "raw-material",
    order = "zz[air-cleaning]",
    enabled = false,
    hide_from_player_crafting = true,
    category = "kr-air-purification",
    energy_required = 480,
    ingredients = { { type = "item", name = "kr-pollution-filter", amount = 1 } },
    results = {
      { type = "item", name = "kr-used-pollution-filter", probability = 0.9, amount = 1 },
    },
    auto_recycle = false,
  },

  -- Technology
  {
    type = "technology",
    name = "kr-air-purification",
    icon = A .. "/graphics/technology-air-purifier.png",
    icon_size = 256,
    prerequisites = { "chemical-science-pack", "engine" },
    unit = {
      count = 275,
      time = 45,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack", 1 },
        { "chemical-science-pack", 1 },
      },
    },
    effects = {
      { type = "unlock-recipe", recipe = "kr-air-purifier" },
      { type = "unlock-recipe", recipe = "kr-pollution-filter" },
      { type = "unlock-recipe", recipe = "kr-air-cleaning" },
      { type = "unlock-recipe", recipe = "kr-restore-used-pollution-filter" },
    },
  },

  -- Entity
  {
    type = "furnace",
    name = "kr-air-purifier",
    icon = A .. "/graphics/icons/air-purifier.png",
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = 0.5, result = "kr-air-purifier" },
    result_inventory_size = 1,
    source_inventory_size = 1,
    max_health = 200,
    corpse = "medium-remnants",
    damaged_trigger_effect = hit_effects.entity(),
    dying_explosion = "explosion",
    collision_box = { { -0.75, -0.75 }, { 0.75, 0.75 } },
    selection_box = { { -0.9, -0.9 }, { 0.9, 0.9 } },
    crafting_categories = { "kr-air-purification" },
    show_recipe_icon = false,
    crafting_speed = 1.0,
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      -- pollution is absorbed by control.lua (configurable radius)
    },
    energy_usage = "75kW",
    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    working_sound = {
      sound = { filename = A .. "/sound/air-purifier.ogg" },
      idle_sound = { filename = "__base__/sound/idle1.ogg" },
    },
    graphics_set = {
      animation = {
        layers = {
          {
            filename = A .. "/graphics/entity/air-purifier.png",
            priority = "high",
            width = 150,
            height = 150,
            shift = { 0, -0.1 },
            frame_count = 16,
            line_length = 4,
            animation_speed = 0.5,
            scale = 0.5,
          },
          {
            filename = A .. "/graphics/entity/air-purifier-sh.png",
            priority = "high",
            width = 164,
            height = 102,
            shift = { 0.22, 0.25 },
            repeat_count = 16,
            draw_as_shadow = true,
            animation_speed = 0.5,
            scale = 0.5,
          },
        },
      },
      water_reflection = {
        pictures = {
          filename = A .. "/graphics/entity/air-purifier-reflection.png",
          priority = "extra-high",
          width = 20,
          height = 25,
          shift = util.by_pixel(0, 40),
          variation_count = 1,
          scale = 5,
        },
        rotate = false,
        orientation_to_variation = false,
      },
    },
    circuit_wire_max_distance = default_circuit_wire_max_distance,
    circuit_connector = circuit_connector_definitions.create_vector(
      universal_connector_template,
      { connector, connector, connector, connector }
    ),
  },
})
