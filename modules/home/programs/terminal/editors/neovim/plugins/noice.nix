{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  programs.nixvim = {
    extraConfigLuaPre = # lua
      ''
        -- required to fix offset_encoding errors
        local notify = vim.notify
        vim.notify = function(msg, ...)
          if msg:match("warning: multiple different client offset_encodings") then
            return
          end

          notify(msg, ...)
        end
      '';

    plugins = {
      noice = {
        enable = true;

        # Hides the title above noice boxes
        cmdline = {
          format = {
            cmdline = {
              pattern = "^:";
              icon = "";
              lang = "vim";
              opts = {
                border = {
                  text = {
                    top = "Cmd";
                  };
                };
              };
            };
            search_down = {
              kind = "search";
              pattern = "^/";
              icon = " ";
              lang = "regex";
            };
            search_up = {
              kind = "search";
              pattern = "^%?";
              icon = " ";
              lang = "regex";
            };
            filter = {
              pattern = "^:%s*!";
              icon = "";
              lang = "bash";
              opts = {
                border = {
                  text = {
                    top = "Bash";
                  };
                };
              };
            };
            lua = {
              pattern = "^:%s*lua%s+";
              icon = "";
              lang = "lua";
            };
            help = {
              pattern = "^:%s*he?l?p?%s+";
              icon = "󰋖";
            };
            input = { };
          };
        };

        messages = {
          view = "mini";
          viewError = "mini";
          viewWarn = "mini";
        };

        lsp = {
          override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };

          progress.enabled = true;
          signature.enabled = true;
        };

        popupmenu.backend = "nui";
        # Doesn't support the standard cmdline completions
        # popupmenu.backend = "cmp";

        presets = {
          bottom_search = false;
          command_palette = true;
          long_message_to_split = true;
          inc_rename = true;
          lsp_doc_border = true;
        };

        routes = [
          {
            filter = {
              event = "msg_show";
              kind = "search_count";
            };
            opts = {
              skip = true;
            };
          }
          {
            # skip progress messages from noisy servers
            filter = {
              event = "lsp";
              kind = "progress";
              cond.__raw = # lua
                ''
                  function(message)
                    local client = vim.tbl_get(message.opts, 'progress', 'client')
                    local servers = { 'jdtls' }

                    for index, value in ipairs(servers) do
                        if value == client then
                            return true
                        end
                    end
                  end
                '';
            };
            opts = {
              skip = true;
            };
          }
        ];

        views = {
          cmdline_popup = {
            border = {
              style = "single";
            };
          };

          confirm = {
            border = {
              style = "single";
              text = {
                top = "";
              };
            };
          };
        };
      };

      notify = {
        enable = true;
      };
    };

    keymaps = mkIf config.programs.nixvim.plugins.telescope.enable [
      {
        mode = "n";
        key = "<leader>fn";
        action = ":Telescope noice<CR>";
        options = {
          desc = "Find notifications";
          silent = true;
        };
      }
    ];
  };
}
