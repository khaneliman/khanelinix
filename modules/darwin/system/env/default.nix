{ lib, ... }:
{
  imports = [
    (lib.modules.importApply (lib.getFile "modules/common/system/env/default.nix") (_: { }))
  ];
}
