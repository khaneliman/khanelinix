{ lib, ... }:
{
  imports = [ (lib.getFile "modules/common/security/sops/default.nix") ];
}
