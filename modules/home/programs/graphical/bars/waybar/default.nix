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
      mkOpt (types.listOf types.str) "Which outputs to use the full size waybar on."
        [ ];
    condensedOutputs =
      mkOpt (types.listOf types.str) "Which outputs to use the smaller size waybar on."
        [ ];
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
            styleDir =
              if config.khanelinix.theme.catppuccin.enable then ./styles/catppuccin else ./styles/base16;
            codexbarStyle = ''
              @import url("${pkgs.khanelinix.codexbar-waybar}/share/codexbar-waybar/codexbar.css");
            '';
            commonStyle = builtins.readFile ./styles/common.css;
            style = builtins.readFile "${styleDir}/style.css";
            controlCenterStyle = builtins.readFile "${styleDir}/control-center.css";
            powerStyle = builtins.readFile "${styleDir}/power.css";
            statsStyle = builtins.readFile "${styleDir}/stats.css";
            workspacesStyle = builtins.readFile "${styleDir}/workspaces.css";
          in
          "${codexbarStyle}${commonStyle}${style}${controlCenterStyle}${powerStyle}${statsStyle}${workspacesStyle}";
      };

      home.packages = [
        pkgs.khanelinix.codexbar-waybar
      ]
      ++ lib.optionals hasAgendaTooltip [
        calendarModule.package
      ];

      systemd.user.services.waybar.Service.EnvironmentFile =
        lib.mkIf hasSopsCopilotToken
          config.sops.templates."waybar-codexbar.env".path;

      sops.secrets = lib.mkIf (config.khanelinix.services.sops.enable or false) {
        weather_config = {
          sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
          path = "${config.home.homeDirectory}/weather_config.json";
        };
      };

      sops.templates."waybar-codexbar.env" = lib.mkIf hasSopsCopilotToken {
        content = ''
          COPILOT_API_TOKEN=${config.sops.placeholder."github/copilot-token"}
        '';
      };
    })
  ];
}
