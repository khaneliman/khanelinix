--- @sync entry
return {
	entry = function()
		local h = cx.active.current.hovered
		local stat = h and (h.stat or h.cha)
		ya.emit("tab_create", stat and stat.is_dir and { h.url } or { current = true })
	end,
}
