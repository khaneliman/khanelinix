{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    attrByPath
    mkBefore
    mkDefault
    mkEnableOption
    mkIf
    optionals
    ;

  cfg = config.khanelinix.services.sunshine;
  userName = config.khanelinix.user.name;
in
{
  options.khanelinix.services.sunshine = {
    enable = mkEnableOption "Sunshine game stream host";
  };

  config = mkIf cfg.enable (
    let
      homeCfg = attrByPath [
        "home-manager"
        "users"
        userName
      ] { } config;
      sunshineCapture = config.services.sunshine.settings.capture or null;
      steamEnabled =
        (config.programs.steam.enable or false)
        || (config.khanelinix.programs.graphical.apps.steam.enable or false);
      protonToolsEnabled = attrByPath [
        "khanelinix"
        "suites"
        "games"
        "protonToolsEnable"
      ] false homeCfg;
      prismLauncherEnabled = attrByPath [
        "khanelinix"
        "programs"
        "graphical"
        "apps"
        "prismlauncher"
        "enable"
      ] false homeCfg;
      flatpakEnabled = config.khanelinix.services.flatpak.enable or false;
      flatpakPackages = config.khanelinix.services.flatpak.extraPackages or [ ];
      hasFlatpakApp =
        appId:
        builtins.any (
          package: if builtins.isAttrs package then package.appId or null == appId else package == appId
        ) flatpakPackages;
      soberEnabled = flatpakEnabled && hasFlatpakApp "org.vinegarhq.Sober";

    in
    {
      services.sunshine = {
        enable = true;
        autoStart = mkDefault true;
        capSysAdmin = mkDefault (sunshineCapture == null || sunshineCapture == "kms");
        openFirewall = mkDefault true;
        applications = {
          env.PATH = mkDefault "$(PATH):/run/current-system/sw/bin:/etc/profiles/per-user/${userName}/bin:$(HOME)/.local/bin";
          apps = mkBefore (
            [
              {
                name = "Desktop";
                "image-path" = "desktop.png";
              }
            ]
            ++ optionals steamEnabled [
              {
                name = "Steam Big Picture";
                detached = [ "setsid steam steam://open/bigpicture" ];
                "prep-cmd" = [
                  {
                    do = "";
                    undo = "setsid steam steam://close/bigpicture";
                  }
                ];
                "image-path" = "steam.png";
              }
            ]
            ++ optionals protonToolsEnabled [
              {
                name = "Heroic";
                detached = [ "setsid heroic" ];
              }
              {
                name = "Lutris";
                detached = [ "setsid lutris" ];
              }
              {
                name = "Bottles";
                detached = [ "setsid bottles" ];
              }
            ]
            ++ optionals prismLauncherEnabled [
              {
                name = "Prism Launcher";
                detached = [ "setsid prismlauncher" ];
              }
            ]
            ++ optionals soberEnabled [
              {
                name = "Sober";
                detached = [ "setsid flatpak run org.vinegarhq.Sober" ];
              }
            ]
          );
        };
      };

      hardware.uinput.enable = true;

      users.users.${userName}.extraGroups = [ "uinput" ];
    }
  );
}
