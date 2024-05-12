{ lib, pkgs, ... }:
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  programs.nixvim = {
    # TODO: is this still needed?
    extraPlugins = with pkgs.vimPlugins; [ webapi-vim ];
  };
}
