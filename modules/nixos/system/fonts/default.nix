{ config
, pkgs
, lib
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.fonts;
in
{
  imports = [ ../../../shared/system/fonts/default.nix ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ font-manager fontpreview ];

    fonts.packages = [ ] ++ cfg.fonts;

    khanelinix.home.file = with inputs; {
      ".local/share/fonts/SanFransisco/SF-Mono/".source = dotfiles.outPath + "/dots/shared/home/.fonts/SanFransisco/SF-Mono";
    };
  };
}
