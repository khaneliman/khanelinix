local fs = os.getenv("HOME") .. "/.config/yazi/plugins/sudo.yazi/assets/fs.nu"

function string:ends_with_char(suffix)
	return self:sub(-#suffix) == suffix
end

function string:is_path()
	local i = self:find("/")
	return self == "." or self == ".." or i and i ~= #self
end

local function list_map(self, f)
	local i = nil
	return function()
		local v
		i, v = next(self, i)
		if v then
			return f(v)
		else
			return nil
		end
	end
end

local get_state = ya.sync(function(_, cmd)
	if cmd == "paste" or cmd == "link" then
		local yanked = {}
		for _, url in pairs(cx.yanked) do
			table.insert(yanked, tostring(url))
		end

		if #yanked == 0 then
			return {}
		end

		return {
			kind = cmd,
			value = {
				is_cut = cx.yanked.is_cut,
				yanked = yanked,
			},
		}
	elseif cmd == "create" then
		return { kind = cmd }
	elseif cmd == "remove" then
		local selected = {}

		if #cx.active.selected ~= 0 then
			for _, url in pairs(cx.active.selected) do
				table.insert(selected, tostring(url))
			end
		else
			table.insert(selected, tostring(cx.active.current.hovered.url))
		end

		return {
			kind = cmd,
			value = {
				selected = selected,
			},
		}
	elseif cmd == "rename" and #cx.active.selected == 0 then
		return {
			kind = cmd,
			value = {
				hovered = tostring(cx.active.current.hovered.url),
			},
		}
	else
		return {}
	end
end)

local function sudo_cmd()
	return { "sudo", "-k", "--" }
end

local function extend_list(self, list)
	for _, value in ipairs(list) do
		table.insert(self, value)
	end
end

local function extend_iter(self, iter)
	for item in iter do
		table.insert(self, item)
	end
end

local function execute(command)
	ya.manager_emit("shell", {
		table.concat(command, " "),
		block = true,
		confirm = true,
	})
end

local function sudo_paste(value)
	local args = sudo_cmd()

	table.insert(args, fs)
	if value.is_cut then
		table.insert(args, "mv")
	else
		table.insert(args, "cp")
	end
	if value.force then
		table.insert(args, "--force")
	end
	extend_iter(args, list_map(value.yanked, ya.quote))

	execute(args)
end

local function sudo_link(value)
	local args = sudo_cmd()

	extend_list(args, { fs, "ln" })
	if value.relative then
		table.insert(args, "--relative")
	end
	extend_iter(args, list_map(value.yanked, ya.quote))

	execute(args)
end

local function sudo_create()
	local name, event = ya.input({
		title = "sudo create:",
		position = { "top-center", y = 2, w = 40 },
	})

	-- Input and confirm
	if event == 1 and not name:is_path() then
		local args = sudo_cmd()

		if name:ends_with_char("/") then
			extend_list(args, { "mkdir", "-p" })
		else
			table.insert(args, "touch")
		end
		table.insert(args, ya.quote(name))

		execute(args)
	end
end

local function sudo_rename(value)
	local new_name, event = ya.input({
		title = "sudo rename:",
		position = { "top-center", y = 2, w = 40 },
	})

	-- Input and confirm
	if event == 1 and not new_name:is_path() then
		local args = sudo_cmd()
		extend_list(args, { "mv", ya.quote(value.hovered), ya.quote(new_name) })
		execute(args)
	end
end

local function sudo_remove(value)
	local args = sudo_cmd()

	extend_list(args, { fs, "rm" })
	if value.is_permanent then
		table.insert(args, "--permanent")
	end
	extend_iter(args, list_map(value.selected, ya.quote))

	execute(args)
end

return {
	entry = function(_, job)
		-- https://github.com/sxyazi/yazi/issues/1553#issuecomment-2309119135
		ya.manager_emit("escape", { visual = true })

		local state = get_state(job.args[1])

		if state.kind == "paste" then
			state.value.force = job.args[2] == "-f"
			sudo_paste(state.value)
		elseif state.kind == "link" then
			state.value.relative = job.args[2] == "-r"
			sudo_link(state.value)
		elseif state.kind == "create" then
			sudo_create()
		elseif state.kind == "remove" then
			state.value.is_permanent = job.args[2] == "-P"
			sudo_remove(state.value)
		elseif state.kind == "rename" then
			sudo_rename(state.value)
		end
	end,
}
