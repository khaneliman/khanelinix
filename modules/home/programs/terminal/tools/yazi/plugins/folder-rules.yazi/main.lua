local function setup()
	ps.sub("ind-sort", function(opt)
		local cwd = tostring(cx.active.current.cwd)
		if
			cwd:find("Downloads$")
			or cwd:find("Screenshots$")
			or cwd:find("DCIM$")
			or cwd:find("tmp$")
			or cwd:find("Trash/files$")
			or cwd:find("Trash$")
			or cwd:find("^/var/log")
			or cwd:find("/%.local/state$")
			or cwd:find("/%.cache$")
		then
			opt.by = "mtime"
			opt.reverse = true
			opt.dir_first = false
		else
			opt.by = "natural"
			opt.reverse = false
			opt.dir_first = true
		end
		return opt
	end)
end

return { setup = setup }
