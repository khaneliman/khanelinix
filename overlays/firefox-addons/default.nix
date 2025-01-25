{ inputs, ... }:
final: _prev: {
  firefox-addons = import inputs.firefox-addons {
    inherit (final) fetchurl;
    inherit (final) lib;
    inherit (final) stdenv;
  };
}
