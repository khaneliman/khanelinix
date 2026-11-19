{
  config,
  inputs,
  lib,
  pkgs,
  system,

  osConfig ? { },
  ...
}:
let
  inherit (lib)
    mkIf
    types
    ;
  inherit (lib.khanelinix) mkOpt;
  inherit (inputs) waybar;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.khanelinix.programs.graphical.bars.waybar;
  hasCopilotToken = lib.hasAttrByPath [ "sops" "secrets" "github/copilot-token" ] config;
  hasSops = config.khanelinix.services.sops.enable or false;
  hasSopsCopilotToken = hasSops && hasCopilotToken;
  syncedCalendarAccounts = lib.filterAttrs (
    _name: account: (account.khal.enable or false) && (account.vdirsyncer.enable or false)
  ) (config.accounts.calendar.accounts or { });
  hasAgendaTooltip =
    (config.khanelinix.programs.terminal.tools.khal.enable or false)
    && (config.khanelinix.services.vdirsyncer.enable or false)
    && syncedCalendarAccounts != { };
  calendarModule = import ./modules/calendar.nix {
    inherit config lib pkgs;
  };

  generateSettings = import ./lib/settings.nix {
    inherit
      config
      lib
      osConfig
      pkgs
      ;
  };
in
{
  options.khanelinix.programs.graphical.bars.waybar = {
    enable = lib.mkEnableOption "waybar in the desktop environment";
    enableDebug = lib.mkEnableOption "debug mode";
    enableInspect = lib.mkEnableOption "inspect mode";
    fullSizeOutputs =
      mkOpt (types.listOf types.str) [ ]
        "Which outputs to use the full size waybar on.";
    condensedOutputs =
      mkOpt (types.listOf types.str) [ ]
        "Which outputs to use the smaller size waybar on.";
    resetTimeFormat = mkOpt (types.enum [
      "provider"
      "local"
      "utc"
    ]) "provider" "How codexbar-waybar renders reset timestamps.";
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "Waybar is only available on linux";
        }
      ];
    })
    (mkIf (cfg.enable && isLinux) {
      programs.waybar = {
        # Waybar configuration
        # See: https://github.com/Alexays/Waybar/wiki/Configuration
        enable = true;
        package = waybar.packages.${system}.waybar;

        systemd = {
          enable = true;
          inherit (cfg) enableDebug enableInspect;
        };

        settings = generateSettings {
          inherit (cfg) fullSizeOutputs condensedOutputs;
        };

        style =
          let
            codexbarStyle = ''
              @import url("${pkgs.khanelinix.codexbar-waybar}/share/codexbar-waybar/codexbar.css");
            '';
            colors = lib.concatStrings (
              lib.mapAttrsToList (
                name: color: "@define-color theme_${name} ${color};\n"
              ) config.khanelinix.theme.active
            );
          in
          codexbarStyle + colors + builtins.readFile ./styles/common.css;
      };

      home.packages = [
        pkgs.khanelinix.codexbar-waybar
      ]
      ++ lib.optionals hasAgendaTooltip [
        calendarModule.package
      ];

      systemd.user.services.waybar.Service = {
        Environment = "CLAUDE_CONFIG_DIR=${config.programs.claude-code.configDir}";
        EnvironmentFile = lib.mkIf hasSopsCopilotToken config.sops.templates."waybar-codexbar.env".path;
      };

      sops.templates."waybar-codexbar.env" = lib.mkIf hasSopsCopilotToken {
        content = ''
          COPILOT_API_TOKEN=${config.sops.placeholder."github/copilot-token"}
        '';
      };
    })
  ];
}
