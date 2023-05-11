{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.python;
in
{
  options.khanelinix.tools.python = with types; {
    enable = mkBoolOpt false "Whether or not to enable python.";
  };

  config = mkIf cfg.enable
    {
      environment.systemPackages = with pkgs; [
        (python311.withPackages (ps: with ps; [ requests ]))
      ];
    };
}
