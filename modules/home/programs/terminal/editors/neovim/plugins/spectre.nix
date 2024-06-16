{ lib, config, ... }:
{
  programs.nixvim = {
    plugins = {
      spectre = {
        enable = true;
      };
    };

    keymaps = lib.mkIf config.programs.nixvim.plugins.spectre.enable [
      {
        mode = "n";
        key = "<leader>rs";
        action = ":Spectre<CR>";
        options = {
          desc = "Spectre toggle";
          silent = true;
        };
      }
    ];
  };
}
