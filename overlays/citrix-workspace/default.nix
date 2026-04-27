{ inputs }:
_final: prev:
let
  citrixPatch = prev.fetchpatch2 {
    name = "nixpkgs-pr-512848-citrix-workspace";
    url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/512848.patch";
    hash = "sha256-iZ4JbutlV9Et+f22oD+862Do7ZX7RXDLrEUmptdw3qs=";
  };

  patchedNixpkgs = prev.applyPatches {
    name = "nixpkgs-citrix-workspace-pr-512848";
    src = inputs.nixpkgs;
    patches = [ citrixPatch ];
  };

  patchedCitrixWorkspacePackages =
    prev.callPackage "${patchedNixpkgs}/pkgs/applications/networking/remote/citrix-workspace"
      { };
in
{
  inherit (patchedCitrixWorkspacePackages)
    citrix_workspace_26_01_0
    citrix_workspace_25_08_10
    ;

  citrix_workspace = patchedCitrixWorkspacePackages.citrix_workspace_26_01_0;
}
