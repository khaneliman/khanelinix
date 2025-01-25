{ khanelinix-lib, ... }:
{
  imports = khanelinix-lib.getDefaultNixFilesRecursive ./.;

  # FIXME: Should be inheriting pkgs with this already set
  nixpkgs.config = {
    allowUnfree = true;
  };
}
