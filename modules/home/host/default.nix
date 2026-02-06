{
  lib,
  hostname ? null,

  ...
}:
let
  inherit (lib) types;
  inherit (lib.khanelinix) mkOpt;
in
{
  options.khanelinix.host = {
    name = mkOpt (types.nullOr types.str) hostname "The host name.";
  };
}
