{ lib, pkgs, ... }:
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      vim-wakatime
    ];

    plugins = {
      lightline.enable = true;

      nvim-autopairs.enable = true;

      nvim-colorizer.enable = true;

      nix-develop.enable = true;

      oil.enable = true;
    };
  };
}
