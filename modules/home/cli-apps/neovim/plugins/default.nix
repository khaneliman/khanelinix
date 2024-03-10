{ lib, ... }:
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  programs.nixvim = {
    plugins = {

      nvim-autopairs.enable = true;

      nvim-colorizer.enable = true;

      oil.enable = true;
    };
  };
}
