_:
let
  get_bufnrs.__raw = # lua
    ''
      function()
        local buf_size_limit = 1024 * 1024 -- 1MB size limit
        local bufs = vim.api.nvim_list_bufs()
        local valid_bufs = {}
        for _, buf in ipairs(bufs) do
          if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf)) < buf_size_limit then
            table.insert(valid_bufs, buf)
          end
        end
        return valid_bufs
      end
    '';
in
{
  programs.nixvim = {
    opts.completeopt = [
      "menu"
      "menuone"
      "noselect"
    ];

    plugins = {
      cmp = {
        enable = true;
        autoEnableSources = true;

        settings = {
          mapping = {
            "<C-d>" = # lua
              "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = # lua
              "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = # lua
              "cmp.mapping.complete()";
            "<C-e>" = # lua
              "cmp.mapping.close()";
            "<Tab>" = # lua
              "cmp.mapping(cmp.mapping.select_next_item({behavior = cmp.SelectBehavior.Select}), {'i', 's'})";
            "<S-Tab>" = # lua
              "cmp.mapping(cmp.mapping.select_prev_item({behavior = cmp.SelectBehavior.Select}), {'i', 's'})";
            "<CR>" = # lua
              "cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace })";
          };

          preselect = # lua
            "cmp.PreselectMode.None";

          snippet.expand = # lua
            "function(args) require('luasnip').lsp_expand(args.body) end";

          sources = [
            {
              name = "nvim_lsp";
              priority = 1000;
              option = {
                inherit get_bufnrs;
              };
            }
            {
              name = "nvim_lsp_signature_help";
              priority = 1000;
              option = {
                inherit get_bufnrs;
              };
            }
            {
              name = "nvim_lsp_document_symbol";
              priority = 1000;
              option = {
                inherit get_bufnrs;
              };
            }
            {
              name = "treesitter";
              priority = 850;
              option = {
                inherit get_bufnrs;
              };
            }
            {
              name = "luasnip";
              priority = 750;
            }
            {
              name = "codeium";
              priority = 300;
            }
            {
              name = "buffer";
              priority = 500;
              option = {
                inherit get_bufnrs;
              };
            }
            {
              name = "path";
              priority = 300;
            }
            {
              name = "cmdline";
              priority = 300;
            }
            {
              name = "spell";
              priority = 300;
            }
            {
              name = "fish";
              priority = 250;
            }
            {
              name = "git";
              priority = 250;
            }
            {
              name = "neorg";
              priority = 250;
            }
            {
              name = "npm";
              priority = 250;
            }
            {
              name = "tmux";
              priority = 250;
            }
            {
              name = "zsh";
              priority = 250;
            }
            {
              name = "calc";
              priority = 150;
            }
            {
              name = "emoji";
              priority = 100;
            }
          ];

          window = {
            completion.__raw = # lua
              ''cmp.config.window.bordered()'';
            documentation.__raw = # lua
              ''cmp.config.window.bordered()'';
          };
        };
      };

      friendly-snippets.enable = true;
      luasnip.enable = true;

      lspkind = {
        enable = true;

        cmp = {
          enable = true;

          menu = {
            buffer = "[Buffer]";
            calc = "[Calc]";
            cmdline = "[Cmdline]";
            codeium = "[Codeium]";
            emoji = "[Emoji]";
            git = "[Git]";
            luasnip = "[Snippet]";
            neorg = "[Neorg]";
            nvim_lsp = "[LSP]";
            nvim_lua = "[API]";
            path = "[Path]";
            spell = "[Spell]";
            treesitter = "[TreeSitter]";
          };
        };
      };
    };
  };
}
