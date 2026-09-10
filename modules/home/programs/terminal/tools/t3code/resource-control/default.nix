{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.t3code;
  inherit (cfg) resourceControl;

  mkRunner =
    name: scratchOnDisk: scopeArgs: ownerArgs:
    pkgs.writeShellScriptBin name ''
      exec ${lib.getExe' pkgs.systemd "systemd-run"} \
        --user --scope --quiet --collect --expand-environment=no \
        --unit="${name}-$$-$RANDOM.scope" \
        --property=OOMPolicy=kill \
        ${lib.optionalString scratchOnDisk ''--setenv=TMPDIR="''${TMPDIR:-/var/tmp}" ''}${
          lib.escapeShellArgs (scopeArgs ++ ownerArgs)
        } -- "$@"
    '';

  agentArgs = [
    "--slice=app-agent-workloads.slice"
    "--property=MemoryHigh=${resourceControl.agent.memoryHigh}"
    "--property=MemoryMax=${resourceControl.agent.memoryMax}"
    "--property=MemorySwapMax=${resourceControl.agent.memorySwapMax}"
  ];
  buildArgs = [
    "--slice=app-build.slice"
    "--property=MemoryHigh=${resourceControl.build.memoryHigh}"
  ];
  backendArgs = [
    "--property=BindsTo=t3code-remote.service"
    "--property=After=t3code-remote.service"
  ];

  # /tmp is a tmpfs, so build scratch left there pins RAM for the whole boot.
  # /var/tmp is disk backed and cleaned by tmpfiles after 30 days. A TMPDIR
  # the caller already exported wins.
  agentRun = mkRunner "agent-run" true agentArgs [ ];
  providerRun = mkRunner "t3code-provider-run" true agentArgs backendArgs;
  buildRun = mkRunner "build-run" false buildArgs [ ];
  t3codeBuild = mkRunner "t3code-build" false buildArgs backendArgs;

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
  options.khanelinix.programs.terminal.tools.t3code.resourceControl = {
    enable = lib.mkEnableOption "resource-limited T3 provider scopes" // {
      default = true;
    };

    agent = {
      memoryHigh = lib.mkOption {
        type = lib.types.str;
        default = "6G";
        description = "Soft memory threshold for each agent scope.";
      };
      memoryMax = lib.mkOption {
        type = lib.types.str;
        default = "8G";
        description = "Hard memory limit for each agent scope.";
      };
      memorySwapMax = lib.mkOption {
        type = lib.types.str;
        default = "2G";
        description = "Swap limit for each agent scope.";
      };
    };

    agentAggregate = {
      memoryHigh = lib.mkOption {
        type = lib.types.str;
        default = "12G";
        description = "Soft memory threshold for the agent workload slice.";
      };
      memoryMax = lib.mkOption {
        type = lib.types.str;
        default = "16G";
        description = "Hard memory limit for the agent workload slice.";
      };
      memorySwapMax = lib.mkOption {
        type = lib.types.str;
        default = "4G";
        description = "Swap limit for the agent workload slice.";
      };
    };

    build = {
      memoryHigh = lib.mkOption {
        type = lib.types.str;
        default = "16G";
        description = "Soft memory threshold for each build scope and slice.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.resourceControl.enable && pkgs.stdenv.hostPlatform.isLinux) {
    home.packages = [
      agentRun
      buildRun
      t3codeBuild
    ];

    systemd.user.slices.app-agent-workloads = {
      Unit.Description = "Resource-limited agent workloads";
      Slice = {
        # Reclaim pressure alone must not terminate interactive agent sessions.
        MemoryHigh = resourceControl.agentAggregate.memoryHigh;
        MemoryMax = resourceControl.agentAggregate.memoryMax;
        MemorySwapMax = resourceControl.agentAggregate.memorySwapMax;
      };
    };

    # A sibling slice lets explicit builds exceed the provider hard caps.
    systemd.user.slices.app-build = {
      Unit.Description = "Soft-limited build workloads";
      Slice = {
        CPUWeight = lib.mkDefault 20;
        IOWeight = lib.mkDefault 20;
        MemoryHigh = resourceControl.build.memoryHigh;
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
