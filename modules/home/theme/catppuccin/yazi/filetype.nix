_:
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
        mime = "application/zip";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/gzip";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/x-tar";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/x-bzip";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/x-bzip2";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/x-7z-compressed";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/x-rar";
        fg = catppuccin.colors.pink.hex;
      }
      # Orphan symbolic links
      {
        name = "*";
        is = "orphan";
        fg = catppuccin.colors.red.hex;
      }
      {
        name = "*";
        is = "link";
        fg = catppuccin.colors.green.hex;
      }
      {
        name = "*/";
        fg = catppuccin.colors.blue.hex;
      }
      {
        name = "*";
        fg = catppuccin.colors.text.hex;
      }
    ];
  };
}
