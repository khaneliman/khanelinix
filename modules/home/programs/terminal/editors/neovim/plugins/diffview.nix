{ config, lib, ... }:
{
  programs.nixvim = {
    plugins = {
      diffview = {
        enable = true;
      };
    };

    keymaps = lib.mkIf config.programs.nixvim.plugins.diffview.enable [
      {
        mode = "n";
        key = "<leader>gd";
        action.__raw = # lua
          ''
            function()
              vim.g.diffview_enabled = not vim.g.diffview_enabled
              if vim.g.diffview_enabled then
                vim.cmd('DiffviewClose')
              else
                vim.cmd('DiffviewOpen')
              end
            end
          '';
        options = {
          desc = "Git Diff toggle";
          silent = true;
        };
      }
    ];
  };
}
