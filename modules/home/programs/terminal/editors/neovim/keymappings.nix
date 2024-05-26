{ config, lib, ... }:
{
  programs.nixvim = {
    extraConfigLuaPre = # lua
      ''
        function bool2str(bool) return bool and "on" or "off" end
      '';

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    keymaps =
      let
        normal =
          lib.mapAttrsToList
            (
              key:
              { action, ... }@attrs:
              {
                mode = "n";
                inherit action key;
                options = attrs.options or { };
              }
            )
            {
              "<Space>" = {
                action = "<NOP>";
              };

              # Esc to clear search results
              "<esc>" = {
                action = ":noh<CR>";
              };

              # Backspace delete in normal
              "<BS>" = {
                action = "<BS>x";
              };

              # fix Y behaviour
              "Y" = {
                action = "y$";
              };

              # back and fourth between the two most recent files
              "<C-c>" = {
                action = ":b#<CR>";
              };

              # navigate to left/right window
              "<leader>[" = {
                action = "<C-w>h";
                options = {
                  desc = "Left window";
                };
              };
              "<leader>]" = {
                action = "<C-w>l";
                options = {
                  desc = "Right window";
                };
              };

              # navigate quickfix list
              "<C-k>" = {
                action = ":cnext<CR>";
              };
              "<C-j>" = {
                action = ":cprev<CR>";
              };

              # resize with arrows
              "<C-Up>" = {
                action = ":resize -2<CR>";
              };
              "<C-Down>" = {
                action = ":resize +2<CR>";
              };
              "<C-Left>" = {
                action = ":vertical resize +2<CR>";
              };
              "<C-Right>" = {
                action = ":vertical resize -2<CR>";
              };

              # move current line up/down
              # M = Alt key
              "<M-k>" = {
                action = ":move-2<CR>";
              };
              "<M-j>" = {
                action = ":move+<CR>";
              };

              "<Leader>w" = {
                action = "<Cmd>w<CR>"; # Action to perform (save the file in this case)
                options = {
                  desc = "Save";
                };
              };

              "j" = {
                action = "v:count == 0 ? 'gj' : 'j'";
                options = {
                  desc = "Move cursor down";
                  expr = true;
                };
              };
              "k" = {
                action = "v:count == 0 ? 'gk' : 'k'";
                options = {
                  desc = "Move cursor up";
                  expr = true;
                };
              };
              "<Leader>q" = {
                action = "<Cmd>confirm q<CR>";
                options = {
                  desc = "Quit";
                };
              };
              "<Leader>n" = {
                action = "<Cmd>enew<CR>";
                options = {
                  desc = "New File";
                };
              };
              "<leader>W" = {
                action = "<Cmd>w!<CR>";
                options = {
                  desc = "Force write";
                };
              };
              "<leader>Q" = {
                action = "<Cmd>q!<CR>";
                options = {
                  desc = "Force quit";
                };
              };
              "|" = {
                action = "<Cmd>vsplit<CR>";
                options = {
                  desc = "Vertical Split";
                };
              };
              "\\" = {
                action = "<Cmd>split<CR>";
                options = {
                  desc = "Horizontal Split";
                };
              };

              "<leader>bC" = {
                action = ":%bd!<CR>";
                options = {
                  desc = "Close all buffers";
                  silent = true;
                };
              };
              "<leader>b]" = {
                action = ":bnext<CR>";
                options = {
                  desc = "Next buffer";
                  silent = true;
                };
              };
              "<TAB>" = {
                action = ":bnext<CR>";
                options = {
                  desc = "Next buffer (default)";
                  silent = true;
                };
              };
              "<leader>b[" = {
                action = ":bprevious<CR>";
                options = {
                  desc = "Previous buffer";
                  silent = true;
                };
              };
              "<S-TAB>" = {
                action = ":bprevious<CR>";
                options = {
                  desc = "Previous buffer";
                  silent = true;
                };
              };

              "<leader>ud" = {
                action.__raw = # lua
                  ''
                    function ()
                      vim.b.disable_diagnostics = not vim.b.disable_diagnostics
                      if vim.b.disable_diagnostics then
                        vim.diagnostic.hide()
                      else
                        vim.diagnostic.show()
                      end
                      vim.notify(string.format("Buffer Diagnostics %s", bool2str(not vim.b.disable_diagnostics), "info"))
                    end'';
                options = {
                  desc = "Toggle Buffer Diagnostics";
                };
              };

              "<leader>uD" = {
                action.__raw = # lua
                  ''
                    function ()
                      vim.g.disable_diagnostics = not vim.g.disable_diagnostics
                      if vim.g.disable_diagnostics then
                        vim.diagnostic.hide()
                      else
                        vim.diagnostic.show()
                      end
                      vim.notify(string.format("Global Diagnostics %s", bool2str(not vim.g.disable_diagnostics), "info"))
                    end'';
                options = {
                  desc = "Toggle Global Diagnostics";
                };
              };

              "<leader>uf" = {
                action.__raw = # lua
                  ''
                    function ()
                      -- vim.g.disable_autoformat = not vim.g.disable_autoformat
                      vim.cmd('FormatToggle!')
                      vim.notify(string.format("Buffer autoformatting %s", bool2str(not vim.b[0].disable_autoformat), "info"))
                    end'';
                options = {
                  desc = "Toggle buffer autoformatting";
                };
              };

              "<leader>uF" = {
                action.__raw = # lua
                  ''
                    function ()
                      -- vim.g.disable_autoformat = not vim.g.disable_autoformat
                      vim.cmd('FormatToggle')
                      vim.notify(string.format("Global autoformatting %s", bool2str(not vim.g.disable_autoformat), "info"))
                    end'';
                options = {
                  desc = "Toggle global autoformatting";
                };
              };

              "<leader>uS" = {
                action.__raw = # lua
                  ''
                    function ()
                      if vim.g.spell_enabled then vim.cmd('setlocal nospell') end
                      if not vim.g.spell_enabled then vim.cmd('setlocal spell') end
                      vim.g.spell_enabled = not vim.g.spell_enabled
                      vim.notify(string.format("Spell %s", bool2str(vim.g.spell_enabled), "info"))
                    end'';
                options = {
                  desc = "Toggle spell";
                };
              };

              "<leader>uw" = {
                action.__raw = # lua
                  ''
                    function ()
                      vim.wo.wrap = not vim.wo.wrap
                      vim.notify(string.format("Wrap %s", bool2str(vim.wo.wrap), "info"))
                    end'';
                options = {
                  desc = "Toggle word wrap";
                };
              };

              "<leader>uh" = {
                action.__raw = # lua
                  ''
                    function ()
                      local curr_foldcolumn = vim.wo.foldcolumn
                      if curr_foldcolumn ~= "0" then vim.g.last_active_foldcolumn = curr_foldcolumn end
                      vim.wo.foldcolumn = curr_foldcolumn == "0" and (vim.g.last_active_foldcolumn or "1") or "0"
                      vim.notify(string.format("Fold Column %s", bool2str(vim.wo.wrap), "info"))
                    end'';
                options = {
                  desc = "Toggle Fold Column";
                };
              };

              "<leader>uc" = {
                action.__raw = # lua
                  ''
                    function ()
                      vim.g.cmp_enabled = not vim.g.cmp_enabled
                      vim.notify(string.format("Completions %s", bool2str(vim.g.cmp_enabled), "info"))
                    end'';
                options = {
                  desc = "Toggle completions";
                };
              };
            };
        visual =
          lib.mapAttrsToList
            (
              key:
              { action, ... }@attrs:
              {
                mode = "v";
                inherit action key;
                options = attrs.options or { };
              }
            )
            {
              # Better indenting
              "<S-Tab>" = {
                action = "<gv";
                options = {
                  desc = "Unindent line";
                };
              };
              "<" = {
                action = "<gv";
                options = {
                  desc = "Unindent line";
                };
              };
              "<Tab>" = {
                action = ">gv";
                options = {
                  desc = "Indent line";
                };
              };
              ">" = {
                action = ">gv";
                options = {
                  desc = "Indent line";
                };
              };

              # Move selected line/block in visual mode
              "K" = {
                action = ":m '<-2<CR>gv=gv";
              };
              "J" = {
                action = ":m '>+1<CR>gv=gv";
              };

              # Backspace delete in visual
              "<BS>" = {
                action = "x";
              };
            };
        insert =
          lib.mapAttrsToList
            (
              key:
              { action, ... }@attrs:
              {
                mode = "i";
                inherit action key;
                options = attrs.options or { };
              }
            )
            {
              # Move selected line/block in insert mode
              "<C-k>" = {
                action = "<C-o>gk";
              };
              "<C-h>" = {
                action = "<Left>";
              };
              "<C-l>" = {
                action = "<Right>";
              };
              "<C-j>" = {
                action = "<C-o>gj";
              };
            };
      in
      config.nixvim.helpers.keymaps.mkKeymaps { options.silent = true; } (normal ++ visual ++ insert);
  };
}
