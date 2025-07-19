{
  lib,
  ...
}:
{
  imports = [
    (lib.getFile "modules/common/programs/terminal/tools/ssh/default.nix")
  ];
}
