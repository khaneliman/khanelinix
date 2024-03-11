{ lib, pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      aerial-nvim
    ];

    keymaps = [{
      mode = "n";
      key = "<leader>ls";
      action = ":AerialToggle<CR>";
      options = {
        desc = "View Symbols";
        silent = true;
      };
    }];
  };
}
