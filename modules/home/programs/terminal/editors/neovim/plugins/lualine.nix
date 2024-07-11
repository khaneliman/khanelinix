{ config, lib, ... }:
let
  inherit (lib) mkIf;

  cond.__raw = # Lua
    ''
      function()
        local buf_size_limit = 1024 * 1024 -- 1MB size limit
        if vim.api.nvim_buf_get_offset(0, vim.api.nvim_buf_line_count(0)) > buf_size_limit then
          return false
        end

        return true
      end
    '';
in
{
  programs.nixvim = {
    plugins.lualine = {
      enable = true;

      disabledFiletypes = {
        statusline = [
          # "neo-tree"
          "startify"
        ];
        winbar = [
          "aerial"
          "dap-repl"
          "neo-tree"
          "neotest-summary"
          "startify"
        ];
      };

      globalstatus = true;

      # +-------------------------------------------------+
      # | A | B | C                             X | Y | Z |
      # +-------------------------------------------------+
      sections = {
        lualine_a = [ "mode" ];
        lualine_b = [ "branch" ];
        lualine_c = [
          "filename"
          "diff"
        ];

        lualine_x = [
          "diagnostics"

          # Show active language server
          {
            name.__raw = # lua
              ''
                function()
                    local msg = ""
                    local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
                    local clients = vim.lsp.get_active_clients()
                    if next(clients) == nil then
                        return msg
                    end
                    for _, client in ipairs(clients) do
                        local filetypes = client.config.filetypes
                        if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                            return client.name
                        end
                    end
                    return msg
                end
              '';
            icon = "";
            color.fg = "#ffffff";
          }
          "encoding"
          "fileformat"
          "filetype"
        ];

        lualine_y = [
          {
            name = "aerial";
            extraConfig = {
              inherit cond;

              # -- The separator to be used to separate symbols in status line.
              sep = " ) ";

              # -- The number of symbols to render top-down. In order to render only 'N' last
              # -- symbols, negative numbers may be supplied. For instance, 'depth = -1' can
              # -- be used in order to render only current symbol.
              depth.__raw = "nil";

              # -- When 'dense' mode is on, icons are not rendered near their symbols. Only
              # -- a single icon that represents the kind of current symbol is rendered at
              # -- the beginning of status line.
              dense = false;

              # -- The separator to be used to separate symbols in dense mode.
              dense_sep = ".";

              # -- Color the symbol icons.
              colored = true;
            };
          }
        ];

        lualine_z = [
          {
            name = "location";
            extraConfig = {
              inherit cond;
            };
          }
        ];
      };

      tabline = mkIf (!config.programs.nixvim.plugins.bufferline.enable) {
        lualine_a = [
          # NOTE: not high priority since i use bufferline now, but should fix left separator color
          {
            name = "buffers";
            extraConfig = {
              symbols = {
                alternate_file = "";
              };
            };
          }
        ];
        lualine_z = [ "tabs" ];
      };

      winbar = {
        lualine_c = [
          {
            name = "navic";
            extraConfig = {
              inherit cond;
            };
          }
        ];

        # TODO: Need to dynamically hide/show component so navic takes precedence on smaller width
        lualine_x = [
          {
            name = "filename";
            extraConfig = {
              newfile_status = true;
              path = 3;
              # Shorten path names to fit navic component
              shorting_target = 150;
            };
          }
        ];
      };
    };
  };
}
