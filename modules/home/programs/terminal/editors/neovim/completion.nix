_: {
  programs.nixvim = {
    opts.completeopt = [
      "menu"
      "menuone"
      "noselect"
    ];

    plugins = {
      cmp-nvim-lsp-signature-help.enable = true;

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
              name = "buffer";
              priority = 500;
              # Words from other open buffers can also be suggested.
              option.get_bufnrs.__raw = # lua
                "vim.api.nvim_list_bufs";
            }
            {
              name = "calc";
              priority = 150;
            }
            {
              name = "cmdline";
              priority = 150;
            }
            {
              name = "codeium";
              priority = 300;
            }
            {
              name = "emoji";
              priority = 100;
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
              name = "luasnip";
              priority = 750;
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
              name = "nvim_lsp";
              priority = 1000;
            }
            {
              name = "path";
              priority = 300;
            }
            {
              name = "tmux";
              priority = 250;
            }
            {
              name = "zsh";
              priority = 250;
            }
          ];
        };
      };

      luasnip.enable = true;

      lspkind = {
        enable = true;

        cmp = {
          enable = true;
          menu = {
            nvim_lsp = "[LSP]";
            nvim_lua = "[api]";
            path = "[path]";
            luasnip = "[snip]";
            buffer = "[buffer]";
            neorg = "[neorg]";
            codeium = "[Codeium]";
            cmdline = "[Cmdline]";
            calc = "[Calc]";
            emoji = "[Emoji]";
          };
        };
      };
    };
  };
}
