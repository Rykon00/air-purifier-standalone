data:extend({
  {
    type = "int-setting",
    name = "aps-radius",
    setting_type = "runtime-global",
    default_value = 2,
    minimum_value = 0,
    maximum_value = 16,
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
