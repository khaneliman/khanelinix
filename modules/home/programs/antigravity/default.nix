{
  config,
  lib,
  pkgs,
  ...
}:
let
  standaloneEnabled = config.khanelinix.programs.graphical.apps.antigravity.enable;
  cliEnabled = config.khanelinix.programs.terminal.tools.antigravity-cli.enable;
  ideEnabled = config.khanelinix.programs.graphical.editors.antigravity-ide.enable;
  mcpEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
  sharedEnabled = standaloneEnabled || cliEnabled || ideEnabled;

  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
  jsonFormat = pkgs.formats.json { };

  declaredConfig = pkgs.writeText "antigravity-global-config.json" (
    builtins.toJSON (
      {
        plugins = {
          okf-memory.enabled = true;
          technical-writing.enabled = true;
        };
      }
      // lib.optionalAttrs standaloneEnabled {
        userSettings = {
          autoExecutionPolicy = "CASCADE_COMMANDS_AUTO_EXECUTION_EAGER";
          customThemeSeedsDark = {
            background = "#1A1B26";
            foregroundOverride = "#A9B1D6";
            primary = "#7AA2F7";
          };
          customThemeSeedsLight = {
            background = "#EAECF0";
            foregroundOverride = "#4C4F69";
            primary = "#8839EF";
          };
          enableTerminalSandbox = false;
          globalPermissionGrants.allow = [
            "mcp(git/git_status)"
            "mcp(git/git_diff)"
            "mcp(git/git_diff_unstaged)"
            "mcp(git/git_add)"
            "mcp(git/git_log)"
          ];
          nonWorkspaceFileAccessPolicy = "AGENT_SETTING_POLICY_ALLOW";
          queuedMessageDeliveryStrategy = "MESSAGE_DELIVERY_STRATEGY_NEXT_INVOCATION";
        };
      }
    )
  );

  antigravityMcpServers =
    config.programs.mcp.servers
    // lib.optionalAttrs (config.programs.mcp.servers ? bevy-brp) {
      bevy-brp = config.programs.mcp.servers.bevy-brp // {
        enabled = false;
      };
    };

  transformMcpServer =
    name: server:
    let
      normalized = lib.hm.mcp.transformMcpServer {
        inherit server;
        extraTransforms = [
          lib.hm.mcp.addType
          (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
        ];
      };
      isRemote = normalized.type == "http";
      cleaned =
        if isRemote then
          removeAttrs normalized [
            "args"
            "command"
            "env"
          ]
        else
          normalized;
    in
    lib.filterAttrs (_: value: value != null && value != [ ] && value != { }) (
      removeAttrs cleaned [ "url" ]
      // lib.optionalAttrs (normalized ? url) {
        serverUrl = normalized.url;
      }
    );

  renderedMcpServers = lib.mapAttrs transformMcpServer antigravityMcpServers;
in
{
  config = lib.mkIf sharedEnabled {
    home = {
      activation.antigravityGlobalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        config_file="${config.home.homeDirectory}/.gemini/config/config.json"
        declared_file=${declaredConfig}

        run mkdir -p "$(dirname "$config_file")"
        temporary_file="$(mktemp "$config_file.tmp.XXXXXX")"

        if [ -f "$config_file" ]; then
          ${lib.getExe pkgs.jq} --slurpfile declared "$declared_file" \
            'if type == "object" then . * $declared[0] else $declared[0] end' \
            "$config_file" > "$temporary_file"
        else
          run cp "$declared_file" "$temporary_file"
        fi

        run mv "$temporary_file" "$config_file"
      '';

      file = {
        ".gemini/GEMINI.md".source = aiTools.base;
        ".gemini/config/plugins/okf-memory".source = lib.mkDefault aiTools.antigravityCli.okfMemoryPlugin;
        ".gemini/config/plugins/technical-writing".source =
          lib.mkDefault aiTools.antigravityCli.technicalWritingPlugin;
      }
      // lib.optionalAttrs (mcpEnabled && renderedMcpServers != { }) {
        ".gemini/config/mcp_config.json".source = jsonFormat.generate "antigravity-mcp-config.json" {
          mcpServers = renderedMcpServers;
        };
      };
    };
  };
}
