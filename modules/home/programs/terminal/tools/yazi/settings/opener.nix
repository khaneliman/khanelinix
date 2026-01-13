{
  config,
  lib,

  ...
}:
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
        run = "exiftool \"$1\"; echo \"Press enter to exit\"; read _";
        block = true;
        desc = "Show EXIF";
        for = "unix";
      }
    ];
    dmg = [
      {
        run = "undmg \"$1\"";
        desc = "Extract here";
        for = "unix";
      }
    ];
    extract = [
      {
        desc = "Extract with atool";
        run = "atool --extract --each --subdir --quiet -- \"$@\"";
        block = true;
      }
      {
        run = "unar \"$1\"";
        desc = "Extract here";
        for = "unix";
      }
      {
        run = "unar \"%1\"";
        desc = "Extract here";
        for = "windows";
      }
    ];
    play = [
      {
        run = "mediainfo \"$1\"; echo \"Press enter to exit\"; read _";
        block = true;
        desc = "Show media info";
        for = "unix";
      }
      (lib.mkIf config.programs.mpv.enable {
        run = "mpv \"$@\"";
        orphan = true;
        for = "unix";
      })
      (lib.mkIf config.programs.mpv.enable {
        run = "mpv \"%1\"";
        orphan = true;
        for = "windows";
      })
    ];
  };
}
