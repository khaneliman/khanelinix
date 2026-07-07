{ khanelinix }:

builtins.mapAttrs (_: value: builtins.attrNames value) (removeAttrs khanelinix.lib [ "overlay" ])
