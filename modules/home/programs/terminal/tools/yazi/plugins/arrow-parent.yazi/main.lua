--- @sync entry
local function entry(_, job)
	local parent = cx.active.parent
	if not parent then
		return
	end

	local target = parent.files[parent.cursor + 1 + job.args[1]]
	local stat = target and (target.stat or target.cha)
	if stat and stat.is_dir then
		ya.emit("cd", { target.url })
	end
end

return { entry = entry }
