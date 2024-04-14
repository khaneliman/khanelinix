_: {
  programs.nixvim = {
    colorschemes.catppuccin = {
      enable = true;

      settings = {
        dim_inactive = {
          enabled = false;
          percentage = 0.25;
        };

        flavour = "macchiato";

        integrations = {
          aerial = true;
          cmp = true;
          dap = {
            enabled = true;
            enable_ui = true;
          };
          gitsigns = true;
          headlines = true;
          markdown = true;
          mason = true;
          mini.enabled = true;

          native_lsp = {
            enabled = true;
            virtual_text = {
              errors = [ "italic" ];
              hints = [ "italic" ];
              warnings = [ "italic" ];
              information = [ "italic" ];
            };
            underlines = {
              errors = [ "underline" ];
              hints = [ "underline" ];
              warnings = [ "underline" ];
              information = [ "underline" ];
            };
            inlay_hints = {
              background = false;
            };
          };

          neogit = true;
          neotree = false;
          noice = true;
          notify = true;
          rainbow_delimiters = true;
          sandwich = true;
          semantic_tokens = true;
          symbols_outline = true;
          telescope = {
            enabled = true;
            style = "nvchad";
          };
          treesitter = true;
          which_key = true;
        };

        transparent_background = true;
      };
    };
  };
}
