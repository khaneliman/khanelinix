--- @sync entry
return {
	entry = function()
		local h = cx.active.current.hovered
		ya.emit("tab_create", h and h.cha.is_dir and { h.url } or { current = true })
	end,
}
