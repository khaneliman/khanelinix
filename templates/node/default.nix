{ buildNpmPackage }:
buildNpmPackage {
  pname = "foo-bar";
  version = "0.1.0";

  src = ./.;

  npmDepsHash = "sha256-cNr83g4aGBg+jY/WaAOOSkcH0cXvqXzkM2Ujzj+cbVk=";
}
