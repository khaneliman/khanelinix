{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ cpsm ];

    plugins = {
      wilder = {
        enable = mkIf (!config.programs.nixvim.plugins.noice.enable) true;

        modes = [
          "/"
          "?"
          ":"
        ];

        pipeline = [
          # lua
          ''
            wilder.branch(
                wilder.python_file_finder_pipeline({
                  file_command = function(ctx, arg)
                    if string.find(arg, '.') ~= nil then
                      return {'fd', '-tf', '-H'}
                    else
                      return {'fd', '-tf'}
                    end
                  end,
                  dir_command = {'fd', '-td'},
                  filters = {'cpsm_filter'},
                }),
                wilder.substitute_pipeline({
                  pipeline = wilder.python_search_pipeline({
                    skip_cmdtype_check = 1,
                    pattern = wilder.python_fuzzy_pattern({
                     start_at_boundary = 0,
                    }),
                  }),
                }),
                wilder.cmdline_pipeline({
                  language = 'python',
                  fuzzy = 1,
                }),
                {
                  wilder.check(function(ctx, x) return x == "" end),
                  wilder.history(),
                },
                wilder.python_search_pipeline({
                  pattern = wilder.python_fuzzy_pattern({
                  start_at_boundary = 0,
                }),
              })
            )
          ''
        ];

        renderer = # lua
          ''
            wilder.renderer_mux({
              [':'] = wilder.popupmenu_renderer(
                wilder.popupmenu_palette_theme({
                  -- 'single', 'double', 'rounded' or 'solid'
                  -- can also be a list of 8 characters, see :h wilder#popupmenu_palette_theme() for more details
                  border = 'rounded',
                  max_height = '50%',      -- max height of the palette
                  min_height = 0,          -- set to the same as 'max_height' for a fixed height window
                  prompt_position = 'top', -- 'top' or 'bottom' to set the location of the prompt
                  reverse = 0,             -- set to 1 to reverse the order of the list, use in combination with 'prompt_position'
                  empty_message = wilder.popupmenu_empty_message_with_spinner(),
                  highlighter = {
                    wilder.pcre2_highlighter(),
                    wilder.lua_fzy_highlighter(),
                  },
                  highlights = {
                    accent = wilder.make_hl('WilderAccent', 'Pmenu', {{a = 1}, {a = 1}, {foreground = '#f4468f'}}),
                  },
                  left = {
                    ' ',
                    wilder.popupmenu_devicons(),
                    wilder.popupmenu_buffer_flags({
                      flags = ' a + ',
                      icons = {['+'] = '', a = '', h = ''},
                    }),
                  },
                  right = {
                    ' ',
                    wilder.popupmenu_scrollbar(),
                  },
                })
              ),
              ['/'] = wilder.wildmenu_renderer({
                highlighter = {
                    wilder.pcre2_highlighter(),
                    wilder.lua_fzy_highlighter(),
                },
                highlights = {
                  accent = wilder.make_hl('WilderAccent', 'Pmenu', {{a = 1}, {a = 1}, {foreground = '#f4468f'}}),
                },
                separator = ' · ',
                left = {' ', wilder.wildmenu_spinner(), ' '},
                right = {' ', wilder.wildmenu_index()},
              }),
              substitute = wilder.wildmenu_renderer({
                highlighter = {
                    wilder.pcre2_highlighter(),
                    wilder.lua_fzy_highlighter(),
                },
                highlights = {
                  accent = wilder.make_hl('WilderAccent', 'Pmenu', {{a = 1}, {a = 1}, {foreground = '#f4468f'}}),
                },
                separator = ' · ',
                left = {' ', wilder.wildmenu_spinner(), ' '},
                right = {' ', wilder.wildmenu_index()},
              }),
            })
          '';
      };
    };
  };
}
