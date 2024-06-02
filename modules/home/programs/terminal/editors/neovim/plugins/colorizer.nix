{ config, lib, ... }:
{
  programs.nixvim = {
    plugins = {
      nvim-colorizer = {
        enable = false;
      };
    };

    keymaps = lib.mkIf config.programs.nixvim.plugins.nvim-colorizer.enable [
      {
        mode = "n";
        key = "<leader>uC";
        action.__raw = # lua
          ''
            function ()
             vim.g.colorizing_enabled = not vim.g.colorizing_enabled
             vim.cmd('ColorizerToggle')
             vim.notify(string.format("Colorizing %s", bool2str(vim.g.colorizing_enabled), "info"))
            end
          '';
        options = {
          desc = "Colorizing toggle";
          silent = true;
        };
      }
    ];
  };
}
