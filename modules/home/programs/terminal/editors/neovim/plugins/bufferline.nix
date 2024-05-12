{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  programs.nixvim = {
    plugins.bufferline =
      let
        mouse = {
          right = # lua
            "'vertical sbuffer %d'";
          close = # lua
            ''
              function(bufnum)
                require("mini.bufremove").delete(bufnum)
              end
            '';
        };
      in
      {
        enable = true;

        mode = "buffers";
        alwaysShowBufferline = true;
        bufferCloseIcon = "󰅖";
        closeCommand.__raw = mouse.close;
        closeIcon = "";
        diagnostics = "nvim_lsp";
        diagnosticsUpdateInInsert = true;
        diagnosticsIndicator = # lua
          ''
            function(count, level, diagnostics_dict, context)
               local s = ""
               for e, n in pairs(diagnostics_dict) do
                  local sym = e == "error" and ""
                     or (e == "warning" and "" or "" )
                  if(sym ~= "") then
                  s = s .. " " .. n .. sym
                  end
               end
               return s
            end
          '';
        # Will make sure all names in bufferline are unique
        enforceRegularTabs = false;

        groups = {
          options = {
            toggleHiddenOnEnter = true;
          };

          items = [
            {
              name = "Tests";
              highlight = {
                underline = true;
                fg = "#a6da95";
                sp = "#494d64";
              };
              priority = 2;
              # icon = "";
              matcher.__raw = # lua
                ''
                  function(buf)
                    return buf.name:match('%test') or buf.name:match('%.spec')
                  end
                '';
            }
            {
              name = "Docs";
              highlight = {
                undercurl = true;
                fg = "#ffffff";
                sp = "#494d64";
              };
              auto_close = false;
              matcher.__raw = # lua
                ''
                  function(buf)
                    return buf.name:match('%.md') or buf.name:match('%.txt')
                  end
                '';
            }
          ];
        };

        # NOTE: fixes colorscheme with transparent_background
        # and better contrast selected tabs
        highlights =
          let
            commonBgColor = "#363a4f";
            commonFgColor = "#1e2030";

            commonSelectedAttrs = {
              bg = commonBgColor;
            };

            # Define a set with common selected attributes
            selectedAttrsSet = builtins.listToAttrs (
              map
                (name: {
                  inherit name;
                  value = commonSelectedAttrs;
                })
                [
                  # "separatorSelected" # Handled uniquely
                  "bufferSelected"
                  "tabSelected"
                  "numbersSelected"
                  "closeButtonSelected"
                  "duplicateSelected"
                  "modifiedSelected"
                  "infoSelected"
                  "warningSelected"
                  "errorSelected"
                  "hintSelected"
                  "diagnosticSelected"
                  "infoDiagnosticSelected"
                  "warningDiagnosticSelected"
                  "errorDiagnosticSelected"
                  "hintDiagnosticSelected"
                ]
            );
          in
          # Merge the common selected attributes with the unique attributes
          selectedAttrsSet
          // {
            fill = {
              bg = commonFgColor;
            };
            separator = {
              fg = commonFgColor;
            };
            separatorVisible = {
              fg = commonFgColor;
            };
            separatorSelected = {
              bg = commonBgColor;
              fg = commonFgColor;
            };
          };

        indicator = {
          style = "icon";
          icon = "▎";
        };

        leftTruncMarker = "";
        maxNameLength = 18;
        maxPrefixLength = 15;
        modifiedIcon = "●";

        numbers.__raw = # lua
          ''
            function(opts)
              return string.format('%s·%s', opts.raise(opts.id), opts.lower(opts.ordinal))
            end
          '';

        persistBufferSort = true;
        rightMouseCommand.__raw = mouse.right;
        rightTruncMarker = "";
        separatorStyle = "slant";
        showBufferCloseIcons = true;
        showBufferIcons = true;
        showCloseIcon = true;
        showTabIndicators = true;
        sortBy = "extension";
        tabSize = 18;

        offsets = [
          {
            filetype = "neo-tree";
            text = "File Explorer";
            text_align = "center";
            highlght = "Directory";
          }
        ];
      };

    keymaps = mkIf config.programs.nixvim.plugins.bufferline.enable [
      {
        mode = "n";
        key = "<leader>bP";
        action = ":BufferLineTogglePin<cr>";
        options = {
          desc = "Toggle Pin";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = ":BufferLinePick<cr>";
        options = {
          desc = "Pick Buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>bsd";
        action = ":BufferLineSortByDirectory<cr>";
        options = {
          desc = "Sort By Directory";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>bse";
        action = ":BufferLineSortByExtension<cr>";
        options = {
          desc = "Sort By Extension";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>bsr";
        action = ":BufferLineSortByRelativeDirectory<cr>";
        options = {
          desc = "Sort By Relative Directory";
          silent = true;
        };
      }
    ];
  };
}
