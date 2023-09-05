{ options
, config
, lib
, inputs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.tools.agenix;
in
{
  options.khanelinix.tools.agenix = with types; {
    enable = mkBoolOpt false "Whether or not to enable agenix.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with inputs; [
      # agenix.packages.${pkgs.system}.default
    ];
  };
}
