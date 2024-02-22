local front_app = sbar.add("item", "front_app", {
  icon = {
    drawing = false
  },
  label = {
    font = {
      style = "Black",
      size = 12.0,
    }
  }
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({
    label = {
      string = env.INFO
    }
  })
end)
