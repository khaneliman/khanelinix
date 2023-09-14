{ options
, config
, lib
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.security.sops;
in
{
  options.khanelinix.security.sops = {
    enable = mkBoolOpt false "Whether to enable sops.";
  };

  config = mkIf cfg.enable { };
}
