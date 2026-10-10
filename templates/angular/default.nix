{ buildNpmPackage }:
buildNpmPackage {
  pname = "foo-bar";
  version = "0.1.0";

  src = ./.;

  npmDepsHash = "sha256-PyOZZ013Thc0Jr8Ov9iAKyG+qcVPqid/iSKg96lOZ3U=";
}
