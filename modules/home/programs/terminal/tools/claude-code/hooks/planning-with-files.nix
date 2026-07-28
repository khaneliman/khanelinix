{
  aiTools,
  lib,
  pkgs,
  ...
}:
let
  skill = aiTools.planningWithFiles.canonicalSkill;
  runtimeInputs = with pkgs; [
    coreutils
    findutils
    gawk
    gnugrep
    gnused
    jq
    python3
  ];
  mkCommand =
    name: script: args:
    lib.getExe (
      pkgs.writeShellApplication {
        inherit name runtimeInputs;
        text = ''
          exec sh ${skill}/scripts/${script} ${args}
        '';
      }
    );
  promptNudge = mkCommand "claude-planning-user-prompt" "inject-plan.sh" "--context=userprompt";
  preCompactNudge = mkCommand "claude-planning-pre-compact" "inject-plan.sh" "--context=precompact";
  stopGate = mkCommand "claude-planning-stop-gate" "gate-stop.sh" "";
  sessionCatchup = lib.getExe (
    pkgs.writeShellApplication {
      name = "claude-planning-session-catchup";
      inherit runtimeInputs;
      text = ''
        input=$(cat)
        cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
        if [ -z "$cwd" ]; then
          cwd="$PWD"
        fi
        exec python3 ${skill}/scripts/session-catchup.py "$cwd"
      '';
    }
  );
  hook = timeout: command: {
    type = "command";
    inherit command timeout;
  };
in
{
  SessionStart = [
    {
      matcher = "*";
      hooks = [ (hook 30 sessionCatchup) ];
    }
  ];

  UserPromptSubmit = [
    {
      matcher = "*";
      hooks = [ (hook 5 promptNudge) ];
    }
  ];

  PreCompact = [
    {
      matcher = "*";
      hooks = [ (hook 5 preCompactNudge) ];
    }
  ];

  Stop = [
    {
      matcher = "";
      hooks = [ (hook 30 stopGate) ];
    }
  ];
}
