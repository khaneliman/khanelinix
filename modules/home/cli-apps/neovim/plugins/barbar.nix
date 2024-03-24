{ config, lib, ... }: {
  programs.nixvim = {
    plugins.barbar = {
      enable = true;

      insertAtEnd = true;

      keymaps = {
        silent = true;

        next = "<TAB>";
        previous = "<S-TAB>";
        close = "<C-w>";
        pin = "<C-p>";
      };
    };

    keymaps = lib.mkIf config.programs.nixvim.plugins.barbar.enable [
      {
        mode = "n";
        key = "<leader>c";
        action = ":BufferClose<CR>";
        options = {
          desc = "Close buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>bc";
        action = ":BufferCloseAllButCurrent<CR>";
        options = {
          desc = "Close all buffers but current";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>bC";
        action = ":bufdo bdelete<CR>";
        options = {
          desc = "Close all buffers";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>b]";
        action = ":BufferNext<CR>";
        options = {
          desc = "Next buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>b[]";
        action = ":BufferPrevious<CR>";
        options = {
          desc = "Previous buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = ":BufferPin<CR>";
        options = {
          desc = "Pin buffer";
          silent = true;
        };
      }
    ];
  };
}
