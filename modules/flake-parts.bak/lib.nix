{
  config,
  lib,
  withSystem,
  ...
}:
{
  _module.args.helpers = import ../lib { inherit lib; };

  flake.lib = lib.genAttrs config.systems (
    lib.flip withSystem (
      { pkgs, ... }:
      {
        check = import ../lib/tests.nix { inherit lib pkgs; };
        helpers = import ../lib { inherit lib pkgs; };
      }
    )
  );
}
