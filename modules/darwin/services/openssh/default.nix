{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.services.openssh;
in
{
  options.${namespace}.services.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys = mkOpt (listOf str) [ default-key ] "The public keys to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
    };
  };
}
