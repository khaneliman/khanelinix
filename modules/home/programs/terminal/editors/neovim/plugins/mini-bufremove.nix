{ lib, config, ... }:
{
  programs.nixvim = {
    plugins = {
      mini = {
        enable = true;

        modules = {
          bufremove = { };
        };
      };
    };

    keymaps = lib.mkIf (lib.hasAttr "bufremove" config.programs.nixvim.plugins.mini.modules) [
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
