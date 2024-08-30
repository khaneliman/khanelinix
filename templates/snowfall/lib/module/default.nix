{ lib, ... }:
let
  inherit (lib) mapAttrs mkOption types;
in
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
      len = lib.stringLength s;
    in
    if len == 0 then "" else (lib.toUpper (lib.substring 0 1 s)) + (lib.substring 1 len s);

  # return an int (1/0) based on boolean value
  # `boolToNum true` -> 1
  boolToNum = bool: if bool then 1 else 0;

  default-attrs = mapAttrs (_key: lib.mkDefault);

  force-attrs = mapAttrs (_key: lib.mkForce);

  nested-default-attrs = mapAttrs (_key: default-attrs);

  nested-force-attrs = mapAttrs (_key: force-attrs);
}
