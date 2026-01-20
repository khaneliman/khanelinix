{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption;

  cfg = config.khanelinix.programs.graphical.apps.citrix-workspace;

  toINI = lib.generators.toINI { };
  iniFormat = pkgs.formats.ini { };
in
{
  options.khanelinix.programs.graphical.apps.citrix-workspace = {
    enable = lib.mkEnableOption "Citrix Workspace";

    settings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          WFClient = {
            AllowAudioInput = "False";
            DPIMatchingEnabled = "False";
          };
          "Thinwire3.0" = {
            DesiredHRES = 1920;
            DesiredVRES = 1080;
          };
        }
      '';
      description = "Configuration for wfclient.ini";
    };
  };

  config = mkIf cfg.enable {
    khanelinix.programs.graphical.apps.citrix-workspace.settings = {
      WFClient = {
        Version = 2;
        KeyboardLayout = "(User Profile)";
        KeyboardType = "(Default)";
        KeyboardMappingFile = "automatic.kbd";
        KeyboardDescription = "Automatic (User Profile)";
        KeyboardEventMode = "Unicode";
        KeyboardSyncMode = "Once";
        CREnabled = "True";
        AllowBidirectionalContentRedirection = "True";
        BrowserProtocol = "HTTPonTCP";
        BrowserTimeout = 5000;
        CDMAllowed = "On";
        ClientPrinterQueue = "On";
        ClientManagement = "On";
        ClientComm = "On";
        MouseSendsControlV = "True";
        MouseDoubleClickTimer = "";
        MouseDoubleClickWidth = "";
        MouseDoubleClickHeight = "";
        Hotkey12Shift = "Ctrl+Shift";
        Hotkey11Shift = "Ctrl+Shift";
        Hotkey10Shift = "Ctrl+Shift";
        Hotkey9Shift = "Ctrl+Shift";
        Hotkey8Shift = "Ctrl+Shift";
        Hotkey7Shift = "Ctrl+Shift";
        Hotkey6Shift = "Ctrl+Shift";
        Hotkey5Shift = "Ctrl+Shift";
        Hotkey4Shift = "Ctrl+Shift";
        Hotkey3Shift = "Ctrl+Shift";
        Hotkey2Shift = "Ctrl+Shift";
        Hotkey1Shift = "Ctrl+Shift";
        IgnoreErrors = "9,15,32";
        AllowAudioInput = "True";
        HDXH264InputEnabled = "True";
        EnhancedResizingEnabled = "True";
        MultiMonitorPnPEnabled = "False";
        MultiMonitorSelectionEnabled = "False";
        SkipPnPDialog = "False";
        DPIMatchingEnabled = "False";
      };
      "Thinwire3.0" = {
        DesiredHRES = 640;
        DesiredVRES = 480;
        DesiredColor = 15;
        PersistentCachePath = "$HOME/.ICAClient/cache";
        PersistentCacheMinBitmap = 2048;
        PersistentCacheEnabled = "Off";
        ApproximateColors = "No";
        UseFullScreen = "False";
      };
    };

    home = {
      packages = [ pkgs.citrix_workspace ];

      # Generate wfclient.ini configuration file
      file.".ICAClient/wfclient.ini" = {
        text = ''
          ;********************************************************************
          ;
          ;    wfclient.ini
          ;
          ;    User configuration for Citrix Workspace for Unix
          ;
          ;    Copyright 1994-2023 Citrix Systems, Inc. All rights reserved.
          ;
          ;********************************************************************
          ${toINI cfg.settings}
        '';
      };

      # Create cache directory
      activation.citrixCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${config.home.homeDirectory}/.ICAClient/cache
      '';
    };
  };
}
