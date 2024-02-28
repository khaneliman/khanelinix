POPUP_TOGGLE = function(name)
  print("Toggling " .. name)
  sbar.exec("sketchybar --set " .. name .. " popup.drawing=toggle")
end

POPUP_OFF = function(name)
  print("Hiding " .. name)
  sbar.exec("sketchybar --set " .. name .. " popup.drawing=off")
end

POPUP_ON = function(name)
  print("Showing " .. name)
  sbar.exec("sketchybar --set " .. name .. " popup.drawing=on")
end

IS_EMPTY = function(s)
  return s == nil or s == ''
end

STR_SPLIT = function(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

PRINT_TABLE = function(t)
  for key, value in pairs(t) do
    if type(value) == "table" then
      print(key, ":")
      PRINT_TABLE(value)
    else
      print(key, ":", value)
    end
  end
end

SLEEP = function(seconds)
  local start = os.time()
  while os.time() - start < seconds do
  end
end
