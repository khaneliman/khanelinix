--- @sync entry
local function entry(_, job)
	local cur = cx.active.current
	for _ = #cx.tabs, job.args[1] do
		ya.emit("tab_create", { cur.cwd })
		if cur.hovered then
			ya.emit("reveal", { cur.hovered.url })
		end
	end
	ya.emit("tab_switch", { job.args[1] })
end

return { entry = entry }
