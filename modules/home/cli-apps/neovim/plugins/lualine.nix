_: {
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
        lualine_c = [ "filename" "diff" ];

        lualine_x = [
          "diagnostics"

          # Show active language server
          {
            name.__raw = ''
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
      };

      tabline = {
        lualine_a = [
          # TODO: fix left separator color
          {
            name = "buffers";
            extraConfig = {
              symbols = {
                alternate_file = "";
              };
            };
          }
        ];
        lualine_z = [
          "tabs"
        ];
      };

      # TODO: breadcrumb style path with custom separator and file icon
      # https://github.com/AstroNvim/astrocommunity/blob/main/lua/astrocommunity/bars-and-lines/heirline-vscode-winbar/init.lua
      winbar = {
        lualine_b = [
          {
            name = "filename";
            extraConfig = {
              newfile_status = true;
              path = 3;
            };
          }
        ];
      };
    };
  };
}
