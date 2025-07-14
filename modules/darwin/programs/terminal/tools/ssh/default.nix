{
  lib,
  ...
}:
{
  imports = [ (lib.getFile "modules/shared/programs/terminal/tools/ssh/default.nix") ];
}
