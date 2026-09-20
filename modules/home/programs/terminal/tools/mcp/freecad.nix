{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.mcp.freecad;
  freecadMcpPackage = pkgs.khanelinix.freecad-mcp;
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
            lib.replaceStrings [ "." ] [ "-" ] (lib.versions.majorMinor pkgs.freecad.version)
          }/Mod";
      description = "FreeCAD user add-on directory; must match the installed FreeCAD version.";
    };
  };

  config = lib.mkIf (config.khanelinix.programs.terminal.tools.mcp.enable && cfg.enable) {
    home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.freecad ];

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
            lib.getExe' pkgs.freecad "FreeCADCmd"
        )
      ];
    };
  };
}
