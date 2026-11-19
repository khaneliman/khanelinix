{
  config,
  self,
  lib,
  ...
}:
let
  tests = import ../lib/tests { inherit self lib; } // {
    testInputGraph = {
      expr = import ../tests/flake-graph.nix;
      expected = {
        devRootNulls = true;
        updateGroupMembership = true;
      };
    };
  };
in
{
  flake.tests = tests // {
    systems = lib.genAttrs config.systems (_system: tests);
  };
}
