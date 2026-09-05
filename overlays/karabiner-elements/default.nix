_: final: prev: {
  karabiner-elements =
    let
      version = "16.2.0";
    in
    prev.karabiner-elements.overrideAttrs (old: {
      inherit version;

      src = final.fetchurl {
        url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v${version}/Karabiner-Elements-${version}.dmg";
        hash = "sha256-xN1v8Xk8FYZZAf9VzTiT/FxMPBymIBiYaotVvlr7HhI=";
      };

      # Karabiner 16.2.0 no longer ships this legacy version marker.
      installPhase =
        builtins.replaceStrings
          [
            ''
              cp "$out/Library/Application Support/org.pqrs/Karabiner-Elements/package-version" "$out/Library/Application Support/org.pqrs/Karabiner-Elements/version"
            ''
          ]
          [ "" ]
          old.installPhase;

      # Keep the helper app bundles pristine so SMAppService can validate their
      # embedded plists and register them with Background Task Management.
      postPatch = "";
    });
}
