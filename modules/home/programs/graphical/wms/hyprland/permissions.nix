{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.wms.hyprland;
  portalPackage =
    if config.wayland.windowManager.hyprland.portalPackage != null then
      config.wayland.windowManager.hyprland.portalPackage
    else
      osConfig.programs.hyprland.portalPackage;

  mkPackagePermission =
    pkg: permissionType: action:
    let
      pname = pkg.pname or (builtins.parseDrvName pkg.name).name;
    in
    {
      binary = "/nix/store/[a-z0-9]{32}-${pname}-[0-9.]*/bin/${pname}";
      type = permissionType;
      mode = action;
    };

  mkPackagePermissions =
    packages: permission: action:
    map (pkg: mkPackagePermission pkg permission action) packages;

  mkPackagePathPermission =
    pkg: subPath: permissionType: action:
    let
      pname = pkg.pname or (builtins.parseDrvName pkg.name).name;
    in
    {
      binary = "/nix/store/[a-z0-9]{32}-${pname}-[0-9.]*/${subPath}";
      type = permissionType;
      mode = action;
    };

  mkLibPermission =
    pkg: libPath: permissionType: action:
    let
      pname = pkg.pname or (builtins.parseDrvName pkg.name).name;
    in
    {
      binary = "/nix/store/[a-z0-9]{32}-${pname}-[0-9.]*/${libPath}";
      type = permissionType;
      mode = action;
    };
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        config.ecosystem = {
          enforce_permissions = cfg.permissions.enforce;
        };

        permission =
          mkPackagePermissions [
            config.programs.hyprlock.package
            config.programs.hyprshot.package
            pkgs.grim
            pkgs.grimblast
            pkgs.hyprpicker
            pkgs.khanelinix.record_screen
          ] "screencopy" "allow"
          ++ [
            (mkPackagePathPermission portalPackage "libexec/.xdg-desktop-portal-hyprland-wrapped" "screencopy"
              "allow"
            )
          ]
          ++
            lib.optional (lib.elem pkgs.hyprlandPlugins.hyprbars config.wayland.windowManager.hyprland.plugins)
              (mkLibPermission pkgs.hyprlandPlugins.hyprbars "lib/libhyprbars.so" "plugin" "allow")
          ++
            lib.optional (lib.elem pkgs.hyprlandPlugins.hyprexpo config.wayland.windowManager.hyprland.plugins)
              (mkLibPermission pkgs.hyprlandPlugins.hyprexpo "lib/libhyprexpo.so" "plugin" "allow");
      };
    };
  };
}
