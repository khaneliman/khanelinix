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
            (key: { action, ... }@attrs: {
              mode = "n";
              inherit action key;
              lua = attrs.lua or false;
              options = attrs.options or { };
            })
            {
              "<Space>" = { action = "<NOP>"; };

              # Esc to clear search results
              "<esc>" = { action = ":noh<CR>"; };

              # fix Y behaviour
              "Y" = { action = "y$"; };

              # back and fourth between the two most recent files
              "<C-c>" = { action = ":b#<CR>"; };

              # close buffer
              "<leader>c" = { action = ":BufferClose<CR>"; options = { desc = "Close buffer"; }; };
              # Buffer mappings
              # "<leader>b" = { action = ""; options = { desc = "Buffer"; }; };
              "<leader>bc" = { action = ":BufferCloseAllButCurrent<CR>"; options = { desc = "Close all buffers but current"; }; }; # requires barbar
              "<leader>bC" = { action = ":bufdo bdelete<CR>"; options = { desc = "Close all buffers"; }; };
              "<leader>b]" = { action = ":BufferNext<CR>"; options = { desc = "Next buffer"; }; };
              "<leader>b[" = { action = ":BufferPrevious<CR>"; options = { desc = "Previous buffer"; }; };
              "<leader>bp" = { action = ":BufferPin<CR>"; options = { desc = "Pin buffer"; }; };

              # navigate to left/right window
              "<leader>[" = { action = "<C-w>h"; options = { desc = "Left window"; }; };
              "<leader>]" = { action = "<C-w>l"; options = { desc = "Right window"; }; };

              # resize with arrows
              "<C-Up>" = { action = ":resize -2<CR>"; };
              "<C-Down>" = { action = ":resize +2<CR>"; };
              "<C-Left>" = { action = ":vertical resize +2<CR>"; };
              "<C-Right>" = { action = ":vertical resize -2<CR>"; };

              # move current line up/down
              # M = Alt key
              "<M-k>" = { action = ":move-2<CR>"; };
              "<M-j>" = { action = ":move+<CR>"; };

              "<Leader>w" = {
                action = "<Cmd>w<CR>"; # Action to perform (save the file in this case)
                options = {
                  desc = "Save";
                };
              };

              "j" = { action = "v:count == 0 ? 'gj' : 'j'"; options = { desc = "Move cursor down"; expr = true; }; };
              "k" = { action = "v:count == 0 ? 'gk' : 'k'"; options = { desc = "Move cursor up"; expr = true; }; };
              "<Leader>q" = { action = "<Cmd>confirm q<CR>"; options = { desc = "Quit"; }; };
              "<Leader>n" = { action = "<Cmd>enew<CR>"; options = { desc = "New File"; }; };
              "<leader>W" = { action = "<Cmd>w!<CR>"; options = { desc = "Force write"; }; };
              "<leader>Q" = { action = "<Cmd>q!<CR>"; options = { desc = "Force quit"; }; };
              "|" = { action = "<Cmd>vsplit<CR>"; options = { desc = "Vertical Split"; }; };
              "\\" = { action = "<Cmd>split<CR>"; options = { desc = "Horizontal Split"; }; };

              "<leader>uf" = {
                action = /*lua*/ ''
                  function ()
                    -- vim.g.disable_autoformat = not vim.g.disable_autoformat
                    vim.cmd('FormatToggle')
                    vim.notify(string.format("Global autoformatting %s", bool2str(not vim.g.disable_autoformat), "info"))
                  end'';
                lua = true;
                options = {
                  desc = "Toggle autoformatting";
                };
              };

              "<leader>us" = {
                action = /*lua*/ ''
                  function ()
                    vim.wo.spell = not vim.wo.spell
                    vim.notify(string.format("Spell %s", bool2str(vim.wo.spell), "info"))
                  end'';
                lua = true;
                options = {
                  desc = "Toggle spell";
                };
              };

              "<leader>uw" = {
                action = /*lua*/ ''
                  function ()
                    vim.wo.wrap = not vim.wo.wrap
                    vim.notify(string.format("Wrap %s", bool2str(vim.wo.wrap), "info"))
                  end'';
                lua = true;
                options = {
                  desc = "Toggle word wrap";
                };
              };

              "<leader>uh" = {
                action = /*lua*/ ''
                  function ()
                    local curr_foldcolumn = vim.wo.foldcolumn
                    if curr_foldcolumn ~= "0" then vim.g.last_active_foldcolumn = curr_foldcolumn end
                    vim.wo.foldcolumn = curr_foldcolumn == "0" and (vim.g.last_active_foldcolumn or "1") or "0"
                    vim.notify(string.format("Fold Column %s", bool2str(vim.wo.wrap), "info"))
                  end'';
                lua = true;
                options = {
                  desc = "Toggle Fold Column";
                };
              };

              "<leader>uc" = {
                action = /*lua*/ ''
                  function ()
                    vim.g.cmp_enabled = not vim.g.cmp_enabled
                    vim.notify(string.format("Completions %s", bool2str(vim.g.cmp_enabled), "info"))
                  end'';
                lua = true;
                options = {
                  desc = "Toggle completions";
                };
              };
            };
        visual =
          lib.mapAttrsToList
            (key: { action, ... }@attrs: {
              mode = "v";
              inherit action key;
              options = attrs.options or { };
              lua = attrs.lua or false;
            })
            {
              # Better indenting
              "<S-Tab>" = { action = "<gv"; options = { desc = "Unindent line"; }; };
              "<" = { action = "<gv"; options = { desc = "Unindent line"; }; };
              "<Tab>" = { action = ">gv"; options = { desc = "Indent line"; }; };
              ">" = { action = ">gv"; options = { desc = "Indent line"; }; };

              # Move selected line/block in visual mode
              "K" = { action = ":m '<-2<CR>gv=gv"; };
              "J" = { action = ":m '>+1<CR>gv=gv"; };
            };
      in
      config.nixvim.helpers.keymaps.mkKeymaps
        {
          options.silent = true;
        }
        (normal ++ visual);
  };
}

