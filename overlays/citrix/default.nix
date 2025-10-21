{ inputs }:
final: _prev:
let
  citrix = import inputs.nixpkgs-citrix-workspace {
    inherit (final.stdenv.hostPlatform) system;
    inherit (final) config;
  };
in
{
  inherit (citrix)
    citrix_workspace
    ;
}
