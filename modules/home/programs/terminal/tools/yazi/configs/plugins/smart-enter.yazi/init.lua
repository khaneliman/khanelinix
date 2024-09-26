return {
	entry = function()
		local h = cx.active.current.hovered
		if h and h.cha.is_dir then
			ya.manager_emit("enter", { hovered = true })
		elseif h and h:is_selected() then
			ya.manager_emit("open", {})
		else
			ya.manager_emit("open", { hovered = true })
		end
	end,
}
