{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.security.pulse-secure;

  start-pulse-vpn =
    pkgs.writeShellScriptBin "start-pulse-vpn" # bash
      ''
        # Grab hostname from cli argument
        HOST="$1"
        DSID=$(${getExe pkgs.khanelinix.pulse-cookie} -n DSID $HOST)
        # NOTE: can be pulse or nc
        sudo ${getExe pkgs.openconnect} --protocol pulse -C DSID=$DSID $HOST
      '';
in
{
  options.khanelinix.security.pulse-secure = {
    enable = mkBoolOpt false "Whether to enable pulse-secure.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      openconnect
      start-pulse-vpn
    ];
  };
}
