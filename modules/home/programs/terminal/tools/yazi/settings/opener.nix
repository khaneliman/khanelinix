{
  config,
  lib,
  pkgs,
  osConfig ? { },

  ...
}:
let
  isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;
in
{
  opener = {
    edit = [
      {
        run = "nvim \"$@\"";
        desc = "$EDITOR";
        block = true;
        for = "unix";
      }
      {
        run = "code \"%*\"";
        orphan = true;
        desc = "code";
        for = "windows";
      }
      {
        run = "code -w \"%*\"";
        block = true;
        desc = "code (block)";
        for = "windows";
      }
    ];
    open = [
      {
        run = "xdg-open \"$@\"";
        desc = "Open";
        for = "linux";
      }
      {
        run = "open \"$@\"";
        desc = "Open";
        for = "macos";
      }
      {
        run = "start \"\" \"%1\"";
        orphan = true;
        desc = "Open";
        for = "windows";
      }
    ];
    reveal = [
      {
        run = "open -R \"$1\"";
        desc = "Reveal";
        for = "macos";
      }
      {
        run = "explorer /select, \"%1\"";
        orphan = true;
        desc = "Reveal";
        for = "windows";
      }
      {
        run = "${lib.getExe pkgs.exiftool} \"$1\"; echo \"Press enter to exit\"; read _";
        block = true;
        desc = "Show EXIF";
        for = "unix";
      }
    ];
    dmg = [
      {
        run = "${lib.getExe pkgs.undmg} \"$1\"";
        desc = "Extract here";
        for = "unix";
      }
    ];
    extract = [
      {
        desc = "Extract with atool";
        run = "${lib.getExe pkgs.atool} --extract --each --subdir --quiet -- \"$@\"";
        block = true;
      }
      {
        run = "${lib.getExe pkgs.unar} \"$1\"";
        desc = "Extract here";
        for = "unix";
      }
      {
        run = "${lib.getExe pkgs.unar} \"%1\"";
        desc = "Extract here";
        for = "windows";
      }
    ];
    play = [
      {
        run = "${lib.getExe pkgs.mediainfo} \"$1\"; echo \"Press enter to exit\"; read _";
        block = true;
        desc = "Show media info";
        for = "unix";
      }
      (lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && !isWSL) {
        run = "${lib.getExe config.programs.mpv.package} \"$@\"";
        orphan = true;
        for = "unix";
      })
      (lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && !isWSL) {
        run = "${lib.getExe config.programs.mpv.package} \"%1\"";
        orphan = true;
        for = "windows";
      })
    ];
  };
}
