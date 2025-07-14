{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.nix-ld;
in
{
  options.khanelinix.programs.terminal.tools.nix-ld = {
    enable = lib.mkEnableOption "nix-ld";
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      package = pkgs.nix-ld;

      libraries = with pkgs; [
        gcc
        icu
        libcxx
        stdenv.cc.cc.lib
        zlib
      ];
    };
  };
}
