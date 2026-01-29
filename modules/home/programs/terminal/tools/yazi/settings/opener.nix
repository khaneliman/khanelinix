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
        run = "xdg-open %s";
        desc = "Open";
        for = "linux";
      }
      {
        run = "open %s";
        desc = "Open";
        for = "macos";
      }
      {
        run = "start \"\" %s";
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
        run = "explorer /select, %s1";
        orphan = true;
        desc = "Reveal";
        for = "windows";
      }
      {
        run = "exiftool %h; echo \"Press enter to exit\"; read _";
        block = true;
        desc = "Show EXIF";
        for = "unix";
      }
    ];
    dmg = [
      {
        run = "undmg %h";
        desc = "Extract here";
        for = "unix";
      }
    ];
    extract = [
      {
        desc = "Extract with atool";
        run = "atool --extract --each --subdir --quiet -- %s";
        block = true;
      }
      {
        run = "unar %h";
        desc = "Extract here";
        for = "unix";
      }
      {
        run = "unar %h";
        desc = "Extract here";
        for = "windows";
      }
    ];
    play = [
      {
        run = "mediainfo %h; echo \"Press enter to exit\"; read _";
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
