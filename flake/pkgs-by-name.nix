{
  inputs,
  lib,
  ...
}:
{
  imports = lib.optional (
    inputs.pkgs-by-name-for-flake-parts ? flakeModule
  ) inputs.pkgs-by-name-for-flake-parts.flakeModule;

  perSystem =
    {
      lib,
      ...
    }:
    lib.optionalAttrs (inputs.pkgs-by-name-for-flake-parts ? flakeModule) {
      pkgsDirectory = ../packages;
    };
}
