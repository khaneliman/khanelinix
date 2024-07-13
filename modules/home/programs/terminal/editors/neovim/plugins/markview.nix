{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [ pkgs.vimPlugins.markview-nvim ];

    extraConfigLuaPre = # lua
      ''
        require("markview").setup()
      '';
  };
}
