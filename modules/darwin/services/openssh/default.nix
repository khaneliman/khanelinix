{
  config,
  lib,
  namespace,
  khanelinix-lib,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    ;
  inherit (khanelinix-lib) mkBoolOpt mkOpt;

  cfg = config.${namespace}.services.openssh;
in
{
  options.${namespace}.services.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys = mkOpt (listOf str) [ ] "The public keys to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
    };
  };
}
