{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix)
    enabled
    mkPackageProfileOption
    suiteProfileIncludes
    ;

  cfg = config.khanelinix.suites.business;
  includes = suiteProfileIncludes config cfg;
  isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;
  annotationEnabled = cfg.annotationEnable && !isWSL;
in
{
  options.khanelinix.suites.business = {
    enable = lib.mkEnableOption "business configuration";
    packageProfile = mkPackageProfileOption "Package profile override for business applications.";
    annotationEnable = lib.mkEnableOption "screenshot annotation applications";
    architectureEnable = lib.mkEnableOption "architecture documentation applications";
    azureDevOpsEnable = lib.mkEnableOption "Azure DevOps backlog integration";
    knowledgeEnable = lib.mkEnableOption "knowledge and requirements applications";
    officeEnable = lib.mkEnableOption "office applications";
    pimEnable = lib.mkEnableOption "personal information management applications";
    planningEnable = lib.mkEnableOption "personal planning applications";
    publishingEnable = lib.mkEnableOption "document publishing applications";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        # FIXME: broken nixpkgs
        # bitwarden-desktop
        jrnl
        np
      ]
      ++ lib.optionals (includes "maximal") [
        slack
      ]
      ++ lib.optionals cfg.architectureEnable [
        mermaid-cli
      ]
      ++ lib.optionals cfg.pimEnable [
        calcurse
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
        [ meetingbar ]
        ++ lib.optionals annotationEnabled [
          macshot
          shottr
        ]
      )
      ++ lib.optionals (stdenv.hostPlatform.isLinux && !isWSL) (
        lib.optionals annotationEnabled [ ksnip ]
        ++ lib.optionals cfg.architectureEnable [ drawio ]
        ++ lib.optionals cfg.officeEnable [
          libreoffice
          p3x-onenote
        ]
      );

    khanelinix = {
      programs = {
        graphical = {
          addons.flameshot.enable = lib.mkDefault annotationEnabled;

          apps = {
            obsidian.enable = lib.mkDefault (cfg.knowledgeEnable && !isWSL);
            # Native Teams cask owns macOS through the Darwin business suite
            teams-for-linux.enable = lib.mkDefault (
              pkgs.stdenv.hostPlatform.isLinux && !isWSL && includes "standard"
            );
            thunderbird.enable = lib.mkDefault (!isWSL && includes "standard"); # No GUI email client in WSL
          };
        };
        terminal = {
          social = {
            slack-term.enable = lib.mkDefault (includes "maximal");
          };
          tools = {
            _1password-cli = lib.mkDefault enabled;
            azure.devOpsEnable = lib.mkDefault cfg.azureDevOpsEnable;
            d2.enable = lib.mkDefault cfg.architectureEnable;
            # khal reads calendars collected by vdirsyncer, which is Linux only
            khal.enable = lib.mkDefault (cfg.pimEnable && pkgs.stdenv.hostPlatform.isLinux);
            pandoc.enable = lib.mkDefault cfg.publishingEnable;
            taskwarrior.enable = lib.mkDefault cfg.planningEnable;
            timewarrior.enable = lib.mkDefault cfg.planningEnable;
            zk.enable = lib.mkDefault cfg.knowledgeEnable;
          };
        };
      };
      services = {
        # FIXME: requires approval
        davmail.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
        vdirsyncer.enable = lib.mkDefault (cfg.pimEnable && pkgs.stdenv.hostPlatform.isLinux && !isWSL);
        # Syncthing carries the knowledge workspace between workstations
        syncthing.enable = lib.mkDefault (cfg.knowledgeEnable && !isWSL);
      };
    };
  };
}
