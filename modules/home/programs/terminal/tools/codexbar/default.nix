{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.khanelinix.programs.terminal.tools.codexbar;
  moduleProviders = [
    {
      id = "codex";
      enabled = config.khanelinix.programs.terminal.tools.codex.enable or false;
    }
    {
      id = "claude";
      enabled = config.khanelinix.programs.terminal.tools.claude-code.enable or false;
    }
    {
      id = "antigravity";
      enabled = config.khanelinix.programs.terminal.tools.antigravity-cli.enable or false;
    }
    {
      id = "copilot";
      enabled = config.khanelinix.programs.terminal.tools.github-copilot-cli.enable or false;
    }
    {
      id = "ollama";
      enabled =
        (config.khanelinix.services.ollama.enable or false) || (config.services.ollama.enable or false);
    }
  ];

  enabledProviderIds =
    map (provider: provider.id) (lib.filter (provider: provider.enabled) moduleProviders)
    ++ cfg.extraProviders;
  initialConfig = (pkgs.formats.json { }).generate "codexbar-config.json" {
    version = 1;
    providers = map (id: {
      inherit id;
      enabled = true;
    }) (lib.unique enabledProviderIds);
  };
  # CodexBar reads $XDG_CONFIG_HOME/codexbar first and only falls back to
  # ~/.codexbar for legacy installs, so seed the XDG location.
  configPath = "${config.xdg.configHome}/codexbar/config.json";
in
{
  options.khanelinix.programs.terminal.tools.codexbar = {
    enable = mkEnableOption "CodexBar CLI and usage provider configuration";

    extraProviders = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional CodexBar provider ids to enable.";
      example = [
        "openrouter"
        "cursor"
      ];
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.khanelinix.codexbar-cli ];

    # CodexBar and its popup mutate this file for provider credentials and
    # settings. Seed only a missing file so later runtime changes stay writable.
    home.activation.initializeCodexbarConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [[ ! -e ${lib.escapeShellArg configPath} && ! -L ${lib.escapeShellArg configPath} ]]; then
        run ${lib.getExe' pkgs.coreutils "install"} -Dm0600 ${initialConfig} ${lib.escapeShellArg configPath}
      fi
    '';
  };
}
