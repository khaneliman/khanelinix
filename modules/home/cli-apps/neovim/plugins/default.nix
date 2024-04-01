{ lib, pkgs, ... }:
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      webapi-vim
      nvim-web-devicons
      nvim-spectre
    ];

    plugins = {
      lightline.enable = true;

      nvim-autopairs.enable = true;

      nix-develop.enable = true;
    };
  };
}
