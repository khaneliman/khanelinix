{
  lib,
  host ? null,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) types;
  inherit (khanelinix-lib) mkOpt;
in
{
  options.khanelinix.host = {
    name = mkOpt (types.nullOr types.str) host "The host name.";
  };
}
