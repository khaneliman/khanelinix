{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ aerial-nvim ];

    keymaps =
      [
        {
          mode = "n";
          key = "<leader>ls";
          action = ":AerialToggle<CR>";
          options = {
            desc = "View Symbols";
            silent = true;
          };
        }
      ]
      ++ lib.optionals config.programs.nixvim.plugins.telescope.enable [
        {
          mode = "n";
          key = "<leader>fS";
          lua = true;
          action = # lua
            ''
              function()
                require("telescope").extensions.aerial.aerial()
              end
            '';
          options = {
            desc = "Search Symbols aerial";
            silent = true;
          };
        }
      ];
  };
}
