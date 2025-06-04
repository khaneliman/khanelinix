{
  lib,
  ...
}:
{
  imports = [ (lib.khanelinix.getFile "modules/shared/programs/terminal/tools/ssh/default.nix") ];
}
