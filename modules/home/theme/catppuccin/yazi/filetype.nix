{ colors }:
{
  filetype = {
    rules = [
      {
        mime = "**/image/*";
        fg = colors.teal.hex;
      }
      {
        mime = "**/video/*";
        fg = colors.yellow.hex;
      }
      {
        mime = "**/audio/*";
        fg = colors.yellow.hex;
      }
      {
        mime = "**/application/{tar,bzip*,7z-compressed,xz,rar,gzip}";
        fg = colors.pink.hex;
      }
      {
        mime = "vfs/{absent,stale}";
        fg = colors.overlay0.hex;
      }
      # Orphan symbolic links
      {
        url = "*";
        is = "orphan";
        fg = colors.red.hex;
      }
      {
        url = "*";
        is = "link";
        fg = colors.green.hex;
      }
      {
        url = "*/";
        fg = colors.blue.hex;
      }
      {
        url = "*";
        fg = colors.text.hex;
      }
    ];
  };
}
