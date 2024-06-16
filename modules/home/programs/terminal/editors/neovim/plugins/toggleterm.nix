{ config, lib, ... }:
{
  programs.nixvim = {
    plugins.toggleterm = {
      enable = true;

      settings = {
        direction = "float";
      };
    };

    keymaps = lib.mkIf config.programs.nixvim.plugins.toggleterm.enable [
      {
        mode = "n";
        key = "<leader>tt";
        action = ":ToggleTerm<CR>";
        options = {
          desc = "Open Terminal";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>tg";
        action.__raw = # lua
          ''
            function()
              local toggleterm = require('toggleterm.terminal')

              toggleterm.Terminal:new({cmd = 'lazygit',hidden = true}):toggle()
            end
          '';
        options = {
          desc = "Open Lazygit";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gg";
        action.__raw = # lua
          ''
            function()
              local toggleterm = require('toggleterm.terminal')

              toggleterm.Terminal:new({cmd = 'lazygit',hidden = true}):toggle()
            end
          '';
        options = {
          desc = "Open Lazygit";
          silent = true;
        };
      }
    ];
  };
}
