{
  lib,
  ...
}:
let
  inherit (lib.khanelinix) mkOpt packageProfileType;
in
{
  options.khanelinix.packageProfile =
    mkOpt packageProfileType "maximal"
      "Package payload profile to use when suite-specific profiles are not set.";
}
