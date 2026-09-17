_: final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux (
  let
    playwright = final.callPackage (prev.path + "/pkgs/development/web/playwright/driver.nix") {
      callPackage =
        path: args:
        let
          package = final.callPackage path args;
        in
        if baseNameOf path == "webkit.nix" then
          package.overrideAttrs (old: {
            # The bundled WPE WebKit binary links against libmanette-0.2.so.0.
            buildInputs = (old.buildInputs or [ ]) ++ [ final.libmanette ];
          })
        else
          package;
    };
  in
  {
    playwright-driver = playwright.playwright-core;
    inherit (playwright) playwright-test;
  }
)
