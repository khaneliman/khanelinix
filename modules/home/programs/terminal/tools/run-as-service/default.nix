{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (lib.strings) optionalString concatStringsSep;
  inherit (lib.attrsets) mapAttrsToList;

  cfg = config.${namespace}.programs.terminal.tools.run-as-service;

  sessionPath = optionalString (config.home.sessionPath != [ ]) ''
    export PATH=${concatStringsSep ":" config.home.sessionPath}:$PATH
  '';

  sessionVariables = concatStringsSep "\n" (
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
  options.${namespace}.programs.terminal.tools.run-as-service = {
    enable = mkBoolOpt false "Whether or not to configure systemd-run support.";
  };
  config = mkIf cfg.enable { home.packages = [ run-as-service ]; };
}
