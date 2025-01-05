{
  lib,
  ...
}:
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/programs/terminal/tools/ssh/default.nix") ];
}
