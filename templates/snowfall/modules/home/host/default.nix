{
  lib,
  host ? null,
  namespace,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkOpt;
in
{
  options.${namespace}.host = {
    name = mkOpt (types.nullOr types.str) host "The host name.";
  };
}
