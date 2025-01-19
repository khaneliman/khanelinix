{
  lib,
  root,
  ...
}:
{
  imports = [ (root + "/modules/shared/programs/terminal/tools/ssh/default.nix") ];
}
