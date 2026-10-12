{
  config,
  lib,
  pkgs,
  getPkgsMaster,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.mcp.freecad;
  freecadMcpPackage = pkgs.khanelinix.freecad-mcp;
  # TODO: remove after hits channel. VTK 9.5.2 fails to configure in
  # nixos-unstable until NixOS/nixpkgs#572295 lands there.
  inherit ((getPkgsMaster pkgs.stdenv.hostPlatform.system { inherit (pkgs) config; })) freecad;
in
{
  options.khanelinix.programs.terminal.tools.mcp.freecad = {
    enable = lib.mkEnableOption "FreeCAD MCP server and add-on";

    addonDirectory = lib.mkOption {
      type = lib.types.str;
      default =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/FreeCAD/v1-1/Mod"
        else
          "${config.xdg.dataHome}/FreeCAD/v${
            lib.replaceStrings [ "." ] [ "-" ] (lib.versions.majorMinor freecad.version)
          }/Mod";
      description = "FreeCAD user add-on directory; must match the installed FreeCAD version.";
    };
  };

  config = lib.mkIf (config.khanelinix.programs.terminal.tools.mcp.enable && cfg.enable) {
    home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ freecad ];

    home.file."${cfg.addonDirectory}/FreeCADMCP".source =
      "${freecadMcpPackage}/share/freecad-mcp/FreeCADMCP";

    programs.mcp.servers.freecad = {
      command = lib.getExe freecadMcpPackage;
      args = [
        "--host"
        "127.0.0.1"
        "--freecadcmd"
        (
          if pkgs.stdenv.hostPlatform.isDarwin then
            "/Applications/FreeCAD.app/Contents/Resources/bin/freecadcmd"
          else
            lib.getExe' freecad "FreeCADCmd"
        )
      ];
    };
  };
}
