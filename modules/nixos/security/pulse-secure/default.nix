{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) getExe mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.security.pulse-secure;

  start-pulse-vpn =
    pkgs.writeShellScriptBin "start-pulse-vpn" # bash
      ''
        # Grab hostname from cli argument
        HOST="$1"
        DSID=$(${getExe pkgs.${namespace}.pulse-cookie} -n DSID $HOST)
        # NOTE: can be pulse or nc
        sudo ${getExe pkgs.openconnect} --protocol pulse -C DSID=$DSID $HOST
      '';
in
{
  options.${namespace}.security.pulse-secure = {
    enable = mkBoolOpt false "Whether to enable pulse-secure.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      openconnect
      start-pulse-vpn
    ];
  };
}
