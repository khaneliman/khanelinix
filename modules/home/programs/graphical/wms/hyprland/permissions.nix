{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.wms.hyprland;

  mkPackagePermission =
    pkg: permission: action:
    let
      pname = pkg.pname or (builtins.parseDrvName pkg.name).name;
    in
    "/nix/store/[a-z0-9]{32}-${pname}-[0-9.]*/bin/${pname}, ${permission}, ${action}";

  mkPackagePermissions =
    packages: permission: action:
    map (pkg: mkPackagePermission pkg permission action) packages;

  mkPackagePathPermission =
    pkg: subPath: permission: action:
    let
      pname = pkg.pname or (builtins.parseDrvName pkg.name).name;
    in
    "/nix/store/[a-z0-9]{32}-${pname}-[0-9.]*/${subPath}, ${permission}, ${action}";

  mkLibPermission =
    pkg: libPath: permission: action:
    let
      pname = pkg.pname or (builtins.parseDrvName pkg.name).name;
    in
    "/nix/store/[a-z0-9]{32}-${pname}-[0-9.]*/${libPath}, ${permission}, ${action}";
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        ecosystem = {
          enforce_permissions = false;
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
            (mkPackagePathPermission config.wayland.windowManager.hyprland.portalPackage
              "libexec/.xdg-desktop-portal-hyprland-wrapped"
              "screencopy"
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
