{
  config,
  lib,
}:
let
  enabledPlugins = config.programs.yazi.plugins;
in
{
  initLua =
    (lib.concatStrings [
      (lib.optionalString (lib.hasAttr "full-border" enabledPlugins) ''
        require("full-border"):setup()
      '')
      (lib.optionalString (lib.hasAttr "git" enabledPlugins) ''
        require("git"):setup()
      '')
      (lib.optionalString (lib.hasAttr "duckdb" enabledPlugins) ''
        require("duckdb"):setup()
      '')
      (lib.optionalString (lib.hasAttr "folder-rules" enabledPlugins) ''
        require("folder-rules"):setup()
      '')
    ])
    + lib.concatStringsSep "\n" [
      /* Lua */ ''
        -- Cross session yank
        require("session"):setup({
        	sync_yanked = true,
        })
      ''
      /* Lua */ ''
        local current_year = os.date("%Y")

        function Linemode:custom()
        	local time = (self._file.cha.mtime or 0) // 1

        	if time > 0 and os.date("%Y", time) == current_year then
        		time = os.date("%b %d %H:%M", time)
        	else
        		time = time and os.date("%b %d  %Y", time) or ""
        	end

        	local size = self._file:size()
        	return ui.Line(string.format(" %s %s ", size and ya.readable_size(size):gsub(" ", "") or "-", time))
        end
      ''
      (lib.optionalString (lib.hasAttr "yatline" enabledPlugins) /* Lua */ ''
        require("yatline"):setup({
          ${
            if config.khanelinix.theme.nord.enable then
              ''theme = require("nord"):setup(),''
            else
              lib.optionalString (lib.hasAttr "yatline-catppuccin" enabledPlugins) ''theme = require("yatline-catppuccin"):setup("macchiato"),''
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

        	return ui.Line({
        		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
        		ui.Span(":"),
        		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
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

        	if h.cha then
        		-- Check if timestamps exist and are not near epoch start (allowing for small variations)
        		if h.cha.ctime and h.cha.ctime > 86400 then -- More than 1 day after epoch
        			formatted_created = tostring(os.date("%Y-%m-%d %H:%M:%S", math.floor(h.cha.ctime)))
        		end

        		if h.cha.mtime and h.cha.mtime > 86400 then -- More than 1 day after epoch
        			formatted_modified = tostring(os.date("%Y-%m-%d %H:%M:%S", math.floor(h.cha.mtime)))
        		end
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
