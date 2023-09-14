{ options
, config
, lib
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.internal) mkBoolOpt mkOpt;
  cfg = config.khanelinix.security.sops;
in
{
  options.khanelinix.security.sops = with types; {
    enable = mkBoolOpt false "Whether to enable sops.";
  };

  config = mkIf cfg.enable { };
}
