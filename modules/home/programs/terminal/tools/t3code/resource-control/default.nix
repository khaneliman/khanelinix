{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.t3code;

  mkRunner =
    name: ownerArgs:
    pkgs.writeShellScriptBin name ''
      exec ${lib.getExe' pkgs.systemd "systemd-run"} \
        --user --scope --quiet --collect --expand-environment=no \
        --slice=app-agent-workloads.slice \
        --property=MemoryHigh=6G \
        --property=MemoryMax=8G \
        --property=MemorySwapMax=2G \
        --property=OOMPolicy=kill \
        ${lib.escapeShellArgs ownerArgs} -- "$@"
    '';

  agentRun = mkRunner "agent-run" [ ];
  providerRun = mkRunner "t3code-provider-run" [
    "--property=BindsTo=t3code-remote.service"
    "--property=After=t3code-remote.service"
  ];

  providerBinaries =
    lib.optionalAttrs (config.programs.codex.enable or false) {
      codex = lib.getExe config.programs.codex.package;
    }
    // lib.optionalAttrs (config.programs.claude-code.enable or false) {
      claudeAgent = lib.getExe config.programs.claude-code.package;
    }
    // lib.optionalAttrs (config.programs.opencode.enable or false) {
      opencode = lib.getExe config.programs.opencode.package;
    }
    // {
      antigravity = lib.getExe pkgs.khanelinix.antigravity-acp;
    };

  scopedBinaries = lib.mapAttrs (
    name: binary:
    pkgs.writeShellScript "t3code-${name}-scoped" ''
      exec ${lib.getExe providerRun} ${lib.escapeShellArg binary} "$@"
    ''
  ) providerBinaries;
in
{
  options.khanelinix.programs.terminal.tools.t3code.resourceControl.enable =
    lib.mkEnableOption "resource-limited T3 provider scopes"
    // {
      default = true;
    };

  config = lib.mkIf (cfg.enable && cfg.resourceControl.enable && pkgs.stdenv.hostPlatform.isLinux) {
    home.packages = [ agentRun ];

    systemd.user.slices.app-agent-workloads = {
      Unit.Description = "Resource-limited agent workloads";
      Slice = {
        MemoryHigh = "12G";
        MemoryMax = "16G";
        MemorySwapMax = "4G";
      };
    };

    programs.t3code.userSettings = {
      # The backend must remain outside the scopes containing provider tools.
      providers = lib.mapAttrs (_name: binary: {
        binaryPath = lib.mkForce (toString binary);
      }) scopedBinaries;

      providerInstances = lib.optionalAttrs (providerBinaries ? claudeAgent) {
        claudeAgent.config.binaryPath = lib.mkForce (toString scopedBinaries.claudeAgent);
      };
    };
  };
}
