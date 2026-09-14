{ lib, ... }:
{
  imports = [ (lib.getFile "modules/common/system/env/default.nix") ];
}
