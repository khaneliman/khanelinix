_: {
  programs.nixvim = {
    options.completeopt = [ "menu" "menuone" "noselect" ];

    plugins = {
      cmp = {
        enable = true;
        autoEnableSources = true;

        settings = {
          mapping = {
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.close()";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
          };

          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";

          sources = [
            {
              name = "buffer";
              # Words from other open buffers can also be suggested.
              option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
            }
            { name = "calc"; }
            { name = "cmdline"; }
            { name = "codeium"; }
            { name = "emoji"; }
            { name = "fish"; }
            { name = "git"; }
            { name = "luasnip"; }
            { name = "neorg"; }
            { name = "npm"; }
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "tmux"; }
            { name = "zsh"; }
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
