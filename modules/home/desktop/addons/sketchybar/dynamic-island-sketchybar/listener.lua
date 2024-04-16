#!/usr/bin/env lua

-- listener=(
-- 	script="$DYNAMIC_ISLAND_DIR/process.sh"
-- 	width=0
-- )
--
-- dynamic-island-sketchybar --add item di_helper_listener center \
-- 	--add event di_helper_listener_event \
-- 	--subscribe di_helper_listener di_helper_listener_event \
-- 	--set di_helper_listener "${listener[@]}"

local di_helper_listener = Sbar.add("item", "di_helper_listener", {
	width = 0,
})

di_helper_listener:subscribe("appswitch", {})

print("di_helper_listener loaded")
