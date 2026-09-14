{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.t3code;
  inherit (cfg) resourceControl;

  # OOMPolicy=continue lets the kernel kill only the offending child. The
  # agent process survives and receives a failed tool result instead of the
  # whole scope disappearing.
  mkRunner =
    name: scratchOnDisk: scopeArgs: ownerArgs:
    pkgs.writeShellScriptBin name ''
      exec ${lib.getExe' pkgs.systemd "systemd-run"} \
        --user --scope --quiet --collect --expand-environment=no \
        --unit="${name}-$$-$RANDOM.scope" \
        --property=OOMPolicy=continue \
        ${lib.optionalString scratchOnDisk ''--setenv=TMPDIR="''${TMPDIR:-/var/tmp}" ''}${
          lib.escapeShellArgs (scopeArgs ++ ownerArgs)
        } -- "$@"
    '';

  # No per-scope memory properties. memory.high does not fail a scope, it
  # parks every allocating process in it, including the agent's own stdio
  # loop, so an over-budget evaluation looked like a silent hang. The shared
  # slice hard cap is the only ceiling.
  agentArgs = [ "--slice=app-agent-workloads.slice" ];
  buildArgs = [ "--slice=app-build.slice" ];
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
    let
      wrapper = pkgs.writeShellScript "t3code-${name}-scoped" ''
        exec ${lib.getExe providerRun} ${lib.escapeShellArg binary} "$@"
      '';
    in
    if name == "antigravity" then
      let
        # T3 resolves the wrapper's real path before looking for the ACP helper.
        package = pkgs.runCommand "t3code-antigravity-scoped" { } ''
          mkdir -p "$out/bin"
          cp ${wrapper} "$out/bin/agy_acp_server.par"
          ln -s ${lib.escapeShellArg "${builtins.dirOf binary}/localharness_external"} "$out/bin/localharness_external"
        '';
      in
      lib.getExe' package "agy_acp_server.par"
    else
      wrapper
  ) providerBinaries;
in
{
  options.khanelinix.programs.terminal.tools.t3code.resourceControl = {
    enable = lib.mkEnableOption "resource-limited T3 provider scopes" // {
      default = true;
    };

    memoryMax = lib.mkOption {
      type = lib.types.str;
      default = "75%";
      description = ''
        Hard memory limit shared by every agent scope. A percentage is
        relative to physical memory. Exceeding it kills the largest process
        in the offending scope; nothing is throttled below it.
      '';
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
      Slice.MemoryMax = resourceControl.memoryMax;
    };

    # A sibling slice lets explicit builds run outside the agent hard cap at
    # lower CPU and IO priority.
    systemd.user.slices.app-build = {
      Unit.Description = "Deprioritized build workloads";
      Slice = {
        CPUWeight = lib.mkDefault 20;
        IOWeight = lib.mkDefault 20;
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
