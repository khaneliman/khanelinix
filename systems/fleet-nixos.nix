{ lib, ... }:
{
  khanelinix.services.openssh.authorizedKeys = lib.mkOptionDefault (
    import ./fleet-authorized-keys.nix
  );
}
