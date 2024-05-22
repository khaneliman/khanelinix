{ lib, ... }:
with lib;
rec {
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };

  mkOpt' = type: default: mkOpt type default null;

  mkBoolOpt = mkOpt types.bool;

  mkBoolOpt' = mkOpt' types.bool;

  enabled = {
    enable = true;
  };

  disabled = {
    enable = false;
  };

  capitalize =
    s:
    let
      len = stringLength s;
    in
    if len == 0 then "" else (lib.toUpper (substring 0 1 s)) + (substring 1 len s);

  # return an int (1/0) based on boolean value
  # `boolToNum true` -> 1
  boolToNum = bool: if bool then 1 else 0;

  default-attrs = mapAttrs (_key: mkDefault);

  nested-default-attrs = mapAttrs (_key: default-attrs);
}
