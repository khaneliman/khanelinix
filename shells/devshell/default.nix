{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
in
{
  # TODO: figure out devshells
  devShells.default = pkgs.mkDevShell {
    packages = [ pkgs.bashInteractive ];
  };
  devShell = self.devShells.default;
}
