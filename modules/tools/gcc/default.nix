{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.gcc;
in
{
  options.khanelinix.tools.gcc = with types; {
    enable = mkBoolOpt false "Whether or not to enable gcc.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gcc
      glib
      glibc
      libgccjit
      stdenvNoCC
    ];
  };
}
