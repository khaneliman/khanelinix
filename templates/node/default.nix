{ buildNpmPackage, importNpmLock }:
buildNpmPackage {
  pname = "foo-bar";
  version = "0.1.0";

  src = ./.;

  # Read integrity hashes from package-lock.json so that lockfile updates need
  # no separate npmDepsHash.
  npmDeps = importNpmLock { npmRoot = ./.; };
  inherit (importNpmLock) npmConfigHook;
}
