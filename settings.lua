data:extend({
  {
    type = "int-setting",
    name = "aps-radius",
    setting_type = "startup",
    default_value = 64,
    minimum_value = 0,
    maximum_value = 512,
    order = "a",
  },
  {
    type = "double-setting",
    name = "aps-absorption",
    setting_type = "runtime-global",
    default_value = 50,
    minimum_value = 1,
    maximum_value = 10000,
    order = "b",
  },
})
