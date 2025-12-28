{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.strings) optionalString;
  inherit (lib.attrsets) mapAttrsToList;

  cfg = config.khanelinix.programs.terminal.tools.run-as-service;

  sessionPath = optionalString (config.home.sessionPath != [ ]) ''
    export PATH=${lib.strings.concatStringsSep ":" config.home.sessionPath}:$PATH
  '';

  sessionVariables = lib.strings.concatStringsSep "\n" (
    mapAttrsToList (key: value: ''
      export ${key}="${toString value}"
    '') config.home.sessionVariables
  );

  apply-hm-env = pkgs.writeShellScript "apply-hm-env" ''
    ${sessionPath}
    ${sessionVariables}
    ${config.home.sessionVariablesExtra}
    exec "$@"
  '';

  # runs processes as systemd transient services
  run-as-service = pkgs.writeShellScriptBin "run-as-service" ''
    exec ${lib.getExe' pkgs.systemd "systemd-run"} \
      --slice=app-manual.slice \
      --property=ExitType=cgroup \
      --user \
      --wait \
      bash -lc "exec ${apply-hm-env} $@"
  '';
in
{
  options.khanelinix.programs.terminal.tools.run-as-service = {
    enable = lib.mkEnableOption "systemd-run support";
  };
  config = mkIf cfg.enable { home.packages = [ run-as-service ]; };
}
