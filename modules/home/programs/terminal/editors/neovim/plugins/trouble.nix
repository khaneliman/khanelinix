{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.nixvim = {
    plugins = {
      trouble = {
        enable = true;

        package =
          # TODO: remove when v3 is packaged
          pkgs.vimUtils.buildVimPlugin {
            name = "trouble.nvim";
            src = pkgs.fetchFromGitHub {
              owner = "folke";
              repo = "trouble.nvim";
              rev = "e2969409cf3f38f69913cc8fd9aa13137aabe760";
              hash = "sha256-Uj4euCnlxbDS37X9+xhchMehhNJaiAz31Wvg73T685o=";
            };
          };
      };
    };

    keymaps = lib.mkIf config.programs.nixvim.plugins.trouble.enable [
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options = {
          desc = "Diagnostics toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        options = {
          desc = "Buffer Diagnostics toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>us";
        action = "<cmd>Trouble symbols toggle focus=false<cr>";
        options = {
          desc = "Symbols toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>xl";
        action = "<cmd>Trouble lsp toggle focus=false win.position=right<cr>";
        options = {
          desc = "LSP Definitions / references / ... toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>xL";
        action = "<cmd>Trouble loclist toggle<cr>";
        options = {
          desc = "Location List toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>xQ";
        action = "<cmd>Trouble qflist toggle<cr>";
        options = {
          desc = "Quickfix List toggle";
          silent = true;
        };
      }
    ];

    plugins.which-key.registrations."<leader>x" = {
      mode = "n";
      name = " Trouble";
    };
  };
}
