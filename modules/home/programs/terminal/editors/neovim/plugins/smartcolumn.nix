{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ smartcolumn-nvim ];

    extraConfigLuaPre = # lua
      ''
        require("smartcolumn").setup()
      '';
  };
}
