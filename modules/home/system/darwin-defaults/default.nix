{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.system.darwin-defaults;
  manager = pkgs.writers.writePython3Bin "darwin-defaults-manager" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./manage.py);
  preferences = [
    {
      domain = "NSGlobalDomain";
      key = "NSAutomaticInlinePredictionEnabled";
      type = "bool";
      value = cfg.inlinePrediction;
    }
    {
      domain = "NSGlobalDomain";
      key = "NSNavPanelExpandedStateForSaveMode";
      type = "bool";
      value = cfg.expandSavePanels;
    }
    {
      domain = "NSGlobalDomain";
      key = "NSNavPanelExpandedStateForSaveMode2";
      type = "bool";
      value = cfg.expandSavePanels;
    }
    {
      domain = "com.apple.desktopservices";
      key = "DSDontWriteNetworkStores";
      type = "bool";
      value = cfg.preventNetworkDsStore;
    }
    {
      domain = "com.apple.desktopservices";
      key = "DSDontWriteUSBStores";
      type = "bool";
      value = cfg.preventUsbDsStore;
    }
  ];
  specification = pkgs.writeText "darwin-defaults.json" (builtins.toJSON preferences);
  baseline = "${config.xdg.stateHome}/khanelinix/darwin-defaults-baseline.json";
  restore = pkgs.writeShellApplication {
    name = "darwin-defaults-restore";
    runtimeInputs = [ manager ];
    text = ''
      exec darwin-defaults-manager restore --baseline ${lib.escapeShellArg baseline}
    '';
  };
in
{
  options.khanelinix.system.darwin-defaults = {
    enable = lib.mkEnableOption "domain-safe macOS user preferences";
    inlinePrediction = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether Apple text fields show inline predictive text.";
    };
    expandSavePanels = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether save dialogs open with the expanded file browser.";
    };
    preventNetworkDsStore = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether Finder avoids .DS_Store files on network volumes.";
    };
    preventUsbDsStore = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether Finder avoids .DS_Store files on USB volumes.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "khanelinix.system.darwin-defaults requires Darwin.";
      }
    ];

    home.packages = [ restore ];

    home.activation.darwinDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe manager} apply \
        --specification ${specification} \
        --baseline ${lib.escapeShellArg baseline}
    '';
  };
}
