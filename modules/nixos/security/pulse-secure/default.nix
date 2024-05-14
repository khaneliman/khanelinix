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
        # Grab host name from cli argument
        HOST="$1"
        DSID=$(${getExe pkgs.khanelinix.pulse-cookie} -n DSID $HOST)
        sudo ${getExe pkgs.openconnect} --protocol nc -C DSID=$DSID $HOST
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
