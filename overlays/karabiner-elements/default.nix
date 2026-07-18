_: final: prev: {
  karabiner-elements =
    let
      version = "16.1.0";
    in
    prev.karabiner-elements.overrideAttrs (_old: {
      inherit version;

      src = final.fetchurl {
        url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v${version}/Karabiner-Elements-${version}.dmg";
        hash = "sha256-vIte4MBkcuHGhzQMsuxdZUtGHiTFB4CJl+X7r/8JOnk=";
      };

      # Keep the helper app bundles pristine so SMAppService can validate their
      # embedded plists and register them with Background Task Management.
      postPatch = "";
    });
}
