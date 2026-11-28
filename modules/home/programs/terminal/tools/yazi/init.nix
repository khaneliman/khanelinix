{
  config,
  lib,
}:
let
  enabledPlugins = config.programs.yazi.plugins;
in
{
  initLua = lib.concatStringsSep "\n" [
    /* Lua */ ''
      -- Cross session yank
      require("session"):setup({
      	sync_yanked = true,
      })
    ''
    /* Lua */ ''
      local current_year = os.date("%Y")

      local function format_timestamp(value, same_year_fmt, other_year_fmt)
      	if not value then
      		return ""
      	end
      	if type(value) == "number" then
      		local ts = value // 1
      		if ts <= 0 then
      			return ""
      		end
      		if os.date("%Y", ts) == current_year then
      			return os.date(same_year_fmt, ts)
      		end
      		return os.date(other_year_fmt, ts)
      	end
      	if value.year == ya.time().year then
      		return value:format({ month = "short", day = "2-digit", hour24 = "2-digit", minute = "2-digit" })
      	end
      	return value:format({ month = "short", day = "2-digit" }) .. "  " .. value.year
      end

      function Linemode:custom()
      	local stat = self._file.stat or self._file.cha
      	local time = format_timestamp(stat and stat.mtime, "%b %d %H:%M", "%b %d  %Y")

      	local size = self._file:size()
      	return ui.Line(string.format(" %s %s ", size and ya.readable_size(size):gsub(" ", "") or "-", time))
      end
    ''
    /* Lua */ ''
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
    ''
    (lib.optionalString (lib.hasAttr "yatline" enabledPlugins) /* Lua */ ''
      require("yatline"):setup({
        ${
          if config.khanelinix.theme.nord.enable then
            ''theme = require("nord"):setup(),''
          else if config.khanelinix.theme.catppuccin.enable then
            lib.optionalString (lib.hasAttr "yatline-catppuccin" enabledPlugins) ''
              theme_dark = require("yatline-catppuccin"):setup("macchiato"),
              theme_light = require("yatline-catppuccin"):setup("latte"),
            ''
          else
            ""
        }
      	show_background = false,
      	header_line = {
      		left = {
      			section_a = {
      				{ type = "line", custom = false, name = "tabs", params = { "left" } },
      			},
      			section_b = {
      				{
      					type = "string",
      					custom = false,
      					name = "tab_path",
      					params = { trimmed = false, max_length = 24, trim_length = 10 },
      				},
      			},
      			section_c = {
      				{ type = "coloreds", custom = false, name = "githead" },
      			},
      		},
      		right = {
      			section_a = {
      				-- {type = "string", custom = false, name = "date", params = {"%A, %d %B %Y"}},
      			},
      			section_b = {
      				-- {type = "string", custom = false, name = "date", params = {"%X"}},
      			},
      			section_c = {},
      		},
      	},
      	status_line = {
      		left = {
      			section_a = {
      				{ type = "string", custom = false, name = "tab_mode" },
      			},
      			section_b = {
      				{ type = "string", custom = false, name = "hovered_size" },
      			},
      			section_c = {
      				{ type = "string", custom = false, name = "hovered_name", params = { { show_symlink = true } } },
      				{ type = "coloreds", custom = false, name = "count" },
      			},
      		},
      		right = {
      			section_a = {
      				{ type = "string", custom = false, name = "cursor_position" },
      			},
      			section_b = {
      				{ type = "string", custom = false, name = "cursor_percentage" },
      			},
      			section_c = {
      				{ type = "string", custom = false, name = "hovered_file_extension", params = { true } },
      				{ type = "coloreds", custom = false, name = "permissions" },
      				{ type = "string", custom = false, name = "hovered_ownership" },
      			},
      		},
      	},
      })
    '')
    (lib.optionalString
      (lib.hasAttr "yatline" enabledPlugins && lib.hasAttr "yatline-githead" enabledPlugins)
      /* Lua */ ''
        require("yatline-githead"):setup()
      ''
    )
    (lib.optionalString (lib.hasAttr "githead" enabledPlugins) /* Lua */ ''
      -- Yatline resets header children during setup.
      require("githead"):setup()
    '')
    (lib.optionalString (!lib.hasAttr "yatline" enabledPlugins) /* Lua */ ''
      Header:children_add(function()
      	if ya.target_family() ~= "unix" then
      		return ui.Line({})
      	end
      	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
      end, 500, Header.LEFT)

      -- Filename and symbolic link path
      function Status:name()
      	local h = cx.active.current.hovered
      	if not h then
      		return ui.Span("")
      	end

      	local linked = ""
      	if h.link_to ~= nil then
      		linked = " -> " .. tostring(h.link_to)
      	end
      	return ui.Span(" " .. h.name .. linked)
      end

      -- File Owner
      Status:children_add(function()
      	local h = cx.active.current.hovered
      	if h == nil or ya.target_family() ~= "unix" then
      		return ui.Line({})
      	end

      	local stat = h.stat or h.cha
      	return ui.Line({
      		ui.Span(ya.user_name(stat.uid) or tostring(stat.uid)):fg("magenta"),
      		ui.Span(":"),
      		ui.Span(ya.group_name(stat.gid) or tostring(stat.gid)):fg("magenta"),
      		ui.Span(" "),
      	})
      end, 500, Status.RIGHT)

      -- File creation and modified date
      Status:children_add(function()
      	local h = cx.active.current.hovered
      	local formatted_created = nil
      	local formatted_modified = nil

      	if h == nil then
      		return ui.Line({})
      	end

      	local stat = h.stat or h.cha
      	local function format_iso(value)
      		if not value then
      			return nil
      		end
      		if type(value) == "number" then
      			if value > 86400 then -- More than 1 day after epoch
      				return tostring(os.date("%Y-%m-%d %H:%M:%S", math.floor(value)))
      			end
      			return nil
      		end
      		return value:format({
      			year = "numeric",
      			month = "2-digit",
      			day = "2-digit",
      			hour24 = "2-digit",
      			minute = "2-digit",
      			second = "2-digit",
      		})
      	end

      	if stat then
      		formatted_created = format_iso(stat.ctime)
      		formatted_modified = format_iso(stat.mtime)
      	end

      	return ui.Line({
      		ui.Span(formatted_created or ""):fg("green"),
      		ui.Span(" "),
      		ui.Span(formatted_modified or ""):fg("blue"),
      		ui.Span(" "),
      	})
      end, 400, Status.RIGHT)
    '')
  ];
}
