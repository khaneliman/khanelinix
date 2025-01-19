{ flake }:
final: _prev: {
  firefox-addons = import flake.inputs.firefox-addons {
    inherit (final) fetchurl;
    inherit (final) lib;
    inherit (final) stdenv;
  };
}
