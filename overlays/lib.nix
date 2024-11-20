{ flake, ... }:
final: prev: {
  lib = prev.lib // {
    khanelinix = flake.lib.khanelinix.override {
      inherit (final) lib;
    };
  };
}
