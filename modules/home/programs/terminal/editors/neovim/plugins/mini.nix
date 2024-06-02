_: {
  programs.nixvim = {
    autoCmd = [
      {
        event = [ "FileType" ];
        pattern = [
          "help"
          "alpha"
          "dashboard"
          "neo-tree"
          "Trouble"
          "trouble"
          "lazy"
          "mason"
          "notify"
          "toggleterm"
          "lazyterm"
        ];
        callback.__raw = # Lua
          ''
            function()
              vim.b.miniindentscope_disable = true
            end
          '';
      }
    ];

    extraConfigLuaPre = # Lua
      ''
        local function in_comment(pattern)
          return function(buf_id)
            local cs = vim.bo[buf_id].commentstring
            if cs == nil or cs == "" then cs = '# %s' end

            -- Extract left and right part relative to '%s'
            local left, right = cs:match('^(.*)%%s(.-)$')
            left, right = vim.trim(left), vim.trim(right)
            -- General ideas:
            -- - Line is commented if it has structure
            -- "whitespace - comment left - anything - comment right - whitespace"
            -- - Highlight pattern only if it is to the right of left comment part
            --   (possibly after some whitespace)
            -- Example output for '/* %s */' commentstring: '^%s*/%*%s*()TODO().*%*/%s*'
            return string.format('^%%s*%s%%s*()%s().*%s%%s*$', vim.pesc(left), pattern, vim.pesc(right))
          end
        end
      '';

    plugins = {
      mini = {
        enable = true;

        modules = {
          ai = { };
          align = { };
          basics = { };
          bracketed = { };
          bufremove = { };
          # TODO: see which i prefer, which-key or this
          # clue = { };
          comment = {
            mappings = {
              comment = "<leader>/";
              comment_line = "<leader>/";
              comment_visual = "<leader>/";
              textobject = "<leader>/";
            };
          };
          diff = {
            view = {
              style = "sign";
            };
          };
          fuzzy = { };
          git = { };
          hipatterns = {
            highlighters = {
              # TODO: enable again if i find a good TODO Telescope replacement from todo-comments
              # fixme = {
              #   pattern.__raw = # Lua
              #     ''in_comment("FIXME")'';
              #   group = "MiniHipatternsFixme";
              # };
              # fix = {
              #   pattern.__raw = # Lua
              #     ''in_comment("FIX")'';
              #   group = "MiniHipatternsFixme";
              # };
              # hack = {
              #   pattern.__raw = # Lua
              #     ''in_comment("HACK")'';
              #   group = "MiniHipatternsHack";
              # };
              # todo = {
              #   pattern.__raw = # Lua
              #     ''in_comment("TODO")'';
              #   group = "MiniHipatternsTodo";
              # };
              # note = {
              #   pattern.__raw = # Lua
              #     ''in_comment("NOTE")'';
              #   group = "MiniHipatternsNote";
              # };
              extmark_opts = {
                priority = 2000;
              };
              hex_color.__raw = # Lua
                ''require("mini.hipatterns").gen_highlighter.hex_color()'';
            };
          };
          indentscope = { };

          map = {
            # __raw = lua code
            # __unkeyed.* = no key, just the value
            integrations = {
              "__unkeyed.builtin_search".__raw = # lua
                "require('mini.map').gen_integration.builtin_search()";
              "__unkeyed.gitsigns".__raw = # lua
                "require('mini.map').gen_integration.gitsigns()";
              "__unkeyed.diagnostic".__raw = # lua
                "require('mini.map').gen_integration.diagnostic()";
            };

            window = {
              winblend = 0;
            };
          };

          pairs = { };

          starter = {
            header = ''
              ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗███████╗██╗     ██╗███╗   ██╗██╗██╗  ██╗
              ██║ ██╔╝██║  ██║██╔══██╗████╗  ██║██╔════╝██║     ██║████╗  ██║██║╚██╗██╔╝
              █████╔╝ ███████║███████║██╔██╗ ██║█████╗  ██║     ██║██╔██╗ ██║██║ ╚███╔╝
              ██╔═██╗ ██╔══██║██╔══██║██║╚██╗██║██╔══╝  ██║     ██║██║╚██╗██║██║ ██╔██╗
              ██║  ██╗██║  ██║██║  ██║██║ ╚████║███████╗███████╗██║██║ ╚████║██║██╔╝ ██╗
              ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝
            '';

            evaluate_single = true;

            items = {
              "__unkeyed.buildtin_actions".__raw = # Lua
                "require('mini.starter').sections.builtin_actions()";
              "__unkeyed.recent_files_current_directory".__raw = # Lua
                "require('mini.starter').sections.recent_files(10, false)";
              "__unkeyed.recent_files".__raw = # Lua
                "require('mini.starter').sections.recent_files(10, true)";
              "__unkeyed.sessions".__raw = # Lua
                "require('mini.starter').sections.sessions(5, true)";
            };

            content_hooks = {
              "__unkeyed.adding_bullet".__raw = # lua
                "require('mini.starter').gen_hook.adding_bullet()";
              "__unkeyed.indexing".__raw = # lua
                "require('mini.starter').gen_hook.indexing('all', { 'Builtin actions' })";
              "__unkeyed.padding".__raw = # Lua
                "require('mini.starter').gen_hook.aligning('center', 'center')";
            };
          };

          surround = {
            mappings = {
              add = "gsa"; # -- Add surrounding in Normal and Visual modes
              delete = "gsd"; # -- Delete surrounding
              find = "gsf"; # -- Find surrounding (to the right)
              find_left = "gsF"; # -- Find surrounding (to the left)
              highlight = "gsh"; # -- Highlight surrounding
              replace = "gsr"; # -- Replace surrounding
              update_n_lines = "gsn"; # -- Update `n_lines`
            };
          };
        };
      };

      telescope = {
        settings = {
          defaults = {
            file_sorter.__raw = # Lua
              ''require('mini.fuzzy').get_telescope_sorter'';
            generic_sorter.__raw = # Lua
              ''require('mini.fuzzy').get_telescope_sorter'';
          };
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>um";
        action.__raw = # lua
          "MiniMap.toggle";
        options = {
          desc = "Toggle MiniMap";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gto";
        action.__raw = # lua
          "MiniDiff.toggle_overlay";
        options = {
          desc = "Toggle Git Overlay";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>c";
        action.__raw = # lua
          ''require("mini.bufremove").delete'';
        options = {
          desc = "Close buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<C-w>";
        action.__raw = # lua
          ''require("mini.bufremove").delete'';
        options = {
          desc = "Close buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>bc";
        action.__raw = # lua
          ''
            function ()
              local current = vim.api.nvim_get_current_buf()

              local get_listed_bufs = function()
                return vim.tbl_filter(function(bufnr)
                 return vim.api.nvim_buf_get_option(bufnr, "buflisted")
                end, vim.api.nvim_list_bufs())
              end

              for _, bufnr in ipairs(get_listed_bufs()) do
                if bufnr ~= current
                then require("mini.bufremove").delete(bufnr)
                end
              end
            end
          '';
        options = {
          desc = "Close all buffers but current";
        };
      }
    ];
  };
}
