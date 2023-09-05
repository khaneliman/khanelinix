{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.cli-apps.fastfetch;
in
{
  options.khanelinix.cli-apps.fastfetch = with types; {
    enable = mkBoolOpt false "Whether or not to enable fastfetch.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fastfetch
    ];
  };
}
