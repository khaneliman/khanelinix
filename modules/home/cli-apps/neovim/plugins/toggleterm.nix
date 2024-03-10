_: {
  programs.nixvim = {
    plugins.toggleterm = {
      enable = true;
      direction = "float";
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>,";
        action = ":ToggleTerm<CR>";
        options = {
          desc = "Toggle terminal";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>tg";
        lua = true;
        action = /*lua*/ ''
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
        lua = true;
        action = /*lua*/ ''
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
