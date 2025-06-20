_: _final: prev:
let
  libxml2' = prev.libxml2.overrideAttrs rec {
    version = "2.13.8";
    src = prev.fetchurl {
      url = "mirror://gnome/sources/libxml2/${prev.lib.versions.majorMinor version}/libxml2-${version}.tar.xz";
      hash = "sha256-J3KUyzMRmrcbK8gfL0Rem8lDW4k60VuyzSsOhZoO6Eo=";
    };
  };
in
{
  citrix_workspace = prev.citrix_workspace.override { libxml2 = libxml2'; };
  citrix_workspace_24_11_0 = prev.citrix_workspace_24_11_0.override { libxml2 = libxml2'; };
  citrix_workspace_24_08_0 = prev.citrix_workspace_24_08_0.override { libxml2 = libxml2'; };
}
