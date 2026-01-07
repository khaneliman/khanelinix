let
  catppuccin = import ../colors.nix;
in
{
  filetype = {
    rules = [
      {
        mime = "image/*";
        fg = catppuccin.colors.teal.hex;
      }
      {
        mime = "video/*";
        fg = catppuccin.colors.yellow.hex;
      }
      {
        mime = "audio/*";
        fg = catppuccin.colors.yellow.hex;
      }
      {
        mime = "application/{tar,bzip*,7z-compressed,xz,rar,gzip}";
        fg = catppuccin.colors.pink.hex;
      }
      # Orphan symbolic links
      {
        url = "*";
        is = "orphan";
        fg = catppuccin.colors.red.hex;
      }
      {
        url = "*";
        is = "link";
        fg = catppuccin.colors.green.hex;
      }
      {
        url = "*/";
        fg = catppuccin.colors.blue.hex;
      }
      {
        url = "*";
        fg = catppuccin.colors.text.hex;
      }
    ];
  };
}
