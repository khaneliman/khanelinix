POPUP_TOGGLE = function(name)
  print("Toggling " .. name)
  sbar.exec("sketchybar --set " .. name .. " popup.drawing=toggle")
end
