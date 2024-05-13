{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  programs.nixvim = {
    plugins.refactoring = {
      enable = true;
    };

    plugins.telescope.enabledExtensions = mkIf config.programs.nixvim.plugins.telescope.enable [
      "refactoring"
    ];

    keymaps =
      [
        {
          mode = "x";
          key = "<leader>re";
          action = ":Refactor extract ";
          options = {
            desc = "Extract";
            silent = true;
          };
        }
        {
          mode = "x";
          key = "<leader>rE";
          action = ":Refactor extract_to_file ";
          options = {
            desc = "Extract to file";
            silent = true;
          };
        }
        {
          mode = "x";
          key = "<leader>rv";
          action = ":Refactor extract_var ";
          options = {
            desc = "Extract var";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>ri";
          action = ":Refactor inline_var<CR>";
          options = {
            desc = "Inline var";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>rI";
          action = ":Refactor inline_func<CR>";
          options = {
            desc = "Inline Func";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>rb";
          action = ":Refactor extract_block<CR>";
          options = {
            desc = "Extract block";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>rB";
          action = ":Refactor extract_block_to_file<CR>";
          options = {
            desc = "Extract block to file";
            silent = true;
          };
        }
      ]
      ++ lib.optionals config.programs.nixvim.plugins.telescope.enable [
        {
          mode = "n";
          key = "<leader>fR";
          lua = true;
          action = # lua
            ''
              function()
                require('telescope').extensions.refactoring.refactors()
              end
            '';
          options = {
            desc = "Find all files";
            silent = true;
          };
        }
      ];
  };
}
