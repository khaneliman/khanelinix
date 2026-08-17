{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.suites.development;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
  tomlFormat = pkgs.formats.toml { };
in
{
  options.khanelinix.suites.development = {
    enable = lib.mkEnableOption "common development configuration";
    aiEnable = lib.mkEnableOption "ai development configuration";
    containerBackend = lib.mkOption {
      type = lib.types.enum [
        "none"
        "colima"
        "docker-desktop"
      ];
      default = "none";
      description = "Container backend projected into the embedded Home Manager configuration.";
    };
    colima = {
      cpu = lib.mkOption {
        type = lib.types.ints.positive;
        default = 4;
        description = "Number of virtual CPUs assigned to Colima.";
      };
      memory = lib.mkOption {
        type = lib.types.ints.positive;
        default = 8;
        description = "Memory in GiB assigned to Colima.";
      };
      disk = lib.mkOption {
        type = lib.types.ints.positive;
        default = 100;
        description = "Disk capacity in GiB assigned to Colima.";
      };
    };
    developerDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "/Applications/Xcode.app/Contents/Developer";
      description = "Expected active Xcode developer directory, or null to leave it unmanaged.";
    };
    devToolsSecurity = lib.mkOption {
      type = lib.types.enum [
        "enabled"
        "disabled"
        "ignore"
      ];
      default = "enabled";
      description = "Expected DevToolsSecurity authorization state.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          config.home-manager.users.${config.khanelinix.user.name}.khanelinix.suites.development.dockerEnable
          == (cfg.containerBackend != "none");
        message = "The embedded Home Manager Docker capability must match khanelinix.suites.development.containerBackend.";
      }
    ];

    homebrew = {
      casks =
        lib.optionals (cfg.containerBackend == "docker-desktop") [
          "docker-desktop"
        ]
        ++ lib.optionals cfg.aiEnable [
          "codexbar"
          "ollamac"
        ];

      masApps = lib.mkIf config.khanelinix.tools.homebrew.masEnable {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };

    khanelinix.home.extraOptions.khanelinix.suites.development.dockerEnable = lib.mkDefault (
      cfg.containerBackend != "none"
    );

    nix.settings = {
      keep-derivations = true;
      keep-outputs = true;
      substituters = lib.optionals cfg.aiEnable [ "https://numtide.cachix.org" ];
      trusted-public-keys = lib.optionals cfg.aiEnable [
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];
    };

    environment.etc = lib.mkIf cfg.aiEnable {
      "codex/requirements.toml".source =
        tomlFormat.generate "codex-requirements" aiTools.codex.managedRequirements;
      "codex/hooks".source = aiTools.codex.hooksDir;
    };

    system.activationScripts.postActivation.text = lib.mkAfter /* Bash */ ''
      echo >&2 "Reconciling Apple developer tool policy..."

      ${lib.optionalString (cfg.developerDirectory != null) ''
        expectedDeveloperDirectory=${lib.escapeShellArg cfg.developerDirectory}
        if [ ! -d "$expectedDeveloperDirectory" ]; then
          echo >&2 "Warning: Expected developer directory does not exist: $expectedDeveloperDirectory"
        elif currentDeveloperDirectory="$(/usr/bin/xcode-select -p 2>/dev/null)"; then
          if [ "$currentDeveloperDirectory" != "$expectedDeveloperDirectory" ]; then
            /usr/bin/xcode-select --switch "$expectedDeveloperDirectory"
          fi
        else
          /usr/bin/xcode-select --switch "$expectedDeveloperDirectory"
        fi
      ''}

      ${lib.optionalString (cfg.devToolsSecurity != "ignore") ''
        expectedDevToolsSecurity=${lib.escapeShellArg cfg.devToolsSecurity}
        if devToolsSecurityOutput="$(LC_ALL=C /usr/sbin/DevToolsSecurity -status 2>&1)"; then
          case "$devToolsSecurityOutput" in
            *"enabled"*) devToolsSecurityState="enabled" ;;
            *"disabled"*) devToolsSecurityState="disabled" ;;
            *) devToolsSecurityState="unknown" ;;
          esac
        else
          devToolsSecurityState="unknown"
        fi

        if [ "$devToolsSecurityState" != "$expectedDevToolsSecurity" ]; then
          case "$expectedDevToolsSecurity" in
            enabled) /usr/sbin/DevToolsSecurity -enable ;;
            disabled) /usr/sbin/DevToolsSecurity -disable ;;
          esac
        fi
      ''}
    '';
  };
}
