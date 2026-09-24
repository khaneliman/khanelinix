{
  system ? builtins.currentSystem,
}:
let
  nixpkgs = (builtins.getFlake (toString ../../..)).inputs.nixpkgs;
  pkgs = import nixpkgs { inherit system; };
in
{
  antigravity-acp = pkgs.callPackage ../../../packages/antigravity-acp/package.nix { };
}
