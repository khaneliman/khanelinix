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
  json = pkgs.formats.json { };

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
      id = "gemini";
      enabled = config.khanelinix.programs.terminal.tools.gemini-cli.enable or false;
    }
    {
      id = "opencode";
      enabled =
        pkgs.stdenv.hostPlatform.isDarwin
        && (config.khanelinix.programs.terminal.tools.opencode.enable or false);
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

  enabledProviders = map (provider: {
    inherit (provider) id;
    enabled = true;
  }) (lib.filter (provider: provider.enabled) moduleProviders);
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
    home = {
      packages = [ pkgs.khanelinix.codexbar-cli ];

      file.".codexbar/config.json".source = json.generate "codexbar-config.json" {
        version = 1;
        providers =
          enabledProviders
          ++ map (id: {
            inherit id;
            enabled = true;
          }) cfg.extraProviders;
      };
    };
  };
}
