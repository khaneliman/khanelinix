{
  config,
  lib,

  ...
}:
{
  opener = {
    edit = [
      {
        run = "nvim %s";
        desc = "$EDITOR";
        block = true;
        for = "unix";
      }
      {
        run = "code %s";
        orphan = true;
        desc = "code";
        for = "windows";
      }
      {
        run = "code -w %s";
        block = true;
        desc = "code (block)";
        for = "windows";
      }
    ];
    open = [
      {
        run = "xdg-open %s1";
        desc = "Open";
        for = "linux";
      }
      {
        run = "open %s";
        desc = "Open";
        for = "macos";
      }
      {
        run = "start \"\" %s1";
        orphan = true;
        desc = "Open";
        for = "windows";
      }
    ];
    reveal = [
      {
        run = "open -R %s1";
        desc = "Reveal";
        for = "macos";
      }
      {
        run = "explorer /select,%s1";
        orphan = true;
        desc = "Reveal";
        for = "windows";
      }
      {
        run = "clear; exiftool %s1; echo \"Press enter to exit\"; read _";
        block = true;
        desc = "Show EXIF";
        for = "unix";
      }
    ];
    dmg = [
      {
        run = "undmg %s1";
        desc = "Extract here";
        for = "unix";
      }
    ];
    extract = [
      {
        run = "ya pub extract --list %s";
        desc = "Extract here";
      }
      {
        desc = "Extract with atool";
        run = "atool --extract --each --subdir --quiet -- %s";
        block = true;
      }
      {
        run = "unar %s";
        desc = "Extract here";
        for = "unix";
      }
      {
        run = "unar %s";
        desc = "Extract here";
        for = "windows";
      }
    ];
    play = [
      {
        run = "mediainfo %s1; echo \"Press enter to exit\"; read _";
        block = true;
        desc = "Show media info";
        for = "unix";
      }
      (lib.mkIf config.programs.mpv.enable {
        run = "mpv %s";
        orphan = true;
        for = "unix";
      })
      (lib.mkIf config.programs.mpv.enable {
        run = "mpv %s";
        orphan = true;
        for = "windows";
      })
    ];
  };
}
