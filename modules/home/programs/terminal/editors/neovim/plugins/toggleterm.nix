_: {
  programs.nixvim = {
    plugins.toggleterm = {
      enable = true;

      settings = {
        direction = "float";
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>tt";
        action = ":ToggleTerm<CR>";
        options = {
          desc = "Toggle terminal";
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
          desc = "Toggle lazygit";
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
          desc = "Toggle lazygit";
          silent = true;
        };
      }
    ];
  };
}
