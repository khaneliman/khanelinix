{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ aerial-nvim ];

    extraConfigLuaPre = # lua
      ''
        require("aerial").setup()
      '';

    keymaps =
      [
        {
          mode = "n";
          key = "<leader>us";
          action = ":AerialToggle<CR>";
          options = {
            desc = "Toggle Symbols";
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
