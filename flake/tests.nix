{
  config,
  self,
  lib,
  ...
}:
let
  tests = import ../lib/tests { inherit self lib; };
in
{
  flake.tests = tests // {
    systems = lib.genAttrs config.systems (_system: tests);
  };
}
