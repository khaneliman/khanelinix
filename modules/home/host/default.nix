{
  lib,
  host ? null,

  ...
}:
let
  inherit (lib) types;
  inherit (flake.inputs.self.lib.khanelinix) mkOpt;
in
{
  options.khanelinix.host = {
    name = mkOpt (types.nullOr types.str) host "The host name.";
  };
}
