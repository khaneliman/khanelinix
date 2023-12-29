{ config
, lib
, ...
}: {
  programs.nixvim = {
    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    keymaps =
      let
        normal =
          lib.mapAttrsToList
            (key: { action, options }: {
              mode = "n";
              inherit action key options;
            })
            {
              "<Space>" = { action = "<NOP>"; options = { }; };

              # Esc to clear search results
              "<esc>" = { action = ":noh<CR>"; options = { }; };

              # fix Y behaviour
              "Y" = { action = "y$"; options = { }; };

              # back and fourth between the two most recent files
              "<C-c>" = { action = ":b#<CR>"; options = { }; };

              # close by Ctrl+x
              "<C-x>" = { action = ":close<CR>"; options = { }; };

              # save by Space+s or Ctrl+s
              "<leader>s" = { action = ":w<CR>"; options = { }; };
              # "<C-s>" = ":w<CR>";

              # navigate to left/right window
              "<leader>h" = { action = "<C-w>h"; options = { }; };
              "<leader>l" = { action = "<C-w>l"; options = { }; };

              # resize with arrows
              "<C-Up>" = { action = ":resize -2<CR>"; options = { }; };
              "<C-Down>" = { action = ":resize +2<CR>"; options = { }; };
              "<C-Left>" = { action = ":vertical resize +2<CR>"; options = { }; };
              "<C-Right>" = { action = ":vertical resize -2<CR>"; options = { }; };

              # move current line up/down
              # M = Alt key
              "<M-k>" = { action = ":move-2<CR>"; options = { }; };
              "<M-j>" = { action = ":move+<CR>"; options = { }; };

              "<leader>rp" = { action = ":!remi push<CR>"; options = { }; };

              "<Leader>w" = {
                action = "<Cmd>w<CR>"; # Action to perform (save the file in this case)
                options = {
                  desc = "Save";
                };
              };

              "j" = { action = "v:count == 0 ? 'gj' : 'j'"; options = { desc = "Move cursor down"; expr = true; }; };
              "k" = { action = "v:count == 0 ? 'gk' : 'k'"; options = { desc = "Move cursor up"; expr = true; }; };
              "<Leader>q" = { action = "<Cmd>confirm q<CR>"; options = { desc = "Quit"; }; };
              "<Leader>Q" = { action = "<Cmd>confirm qall<CR>"; options = { desc = "Quit all"; }; };
              "<Leader>n" = { action = "<Cmd>enew<CR>"; options = { desc = "New File"; }; };
              "<C-s>" = { action = "<Cmd>w!<CR>"; options = { desc = "Force write"; }; };
              "<C-q>" = { action = "<Cmd>q!<CR>"; options = { desc = "Force quit"; }; };
              "|" = { action = "<Cmd>vsplit<CR>"; options = { desc = "Vertical Split"; }; };
              "\\" = { action = "<Cmd>split<CR>"; options = { desc = "Horizontal Split"; }; };
            };
        visual =
          lib.mapAttrsToList
            (key: { action, options }: {
              mode = "v";
              inherit action key options;
            })
            {
              # Better indenting
              "<S-Tab>" = { action = "<gv"; options = { desc = "Unindent line"; }; };
              "<" = { action = "<gv"; options = { desc = "Unindent line"; }; };
              "<Tab>" = { action = ">gv"; options = { desc = "Indent line"; }; };
              ">" = { action = ">gv"; options = { desc = "Indent line"; }; };

              # Move selected line/block in visual mode
              "K" = { action = ":m '<-2<CR>gv=gv"; options = { }; };
              "J" = { action = ":m '>+1<CR>gv=gv"; options = { }; };
            };
      in
      config.nixvim.helpers.keymaps.mkKeymaps
        { options.silent = true; }
        (normal ++ visual);
  };
}
