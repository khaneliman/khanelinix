# nixpkgs' cargo setup hook forces Rust crates onto system libraries
# (AWS_LC_SYS_USE_SYSTEM, LIBSQLITE3_SYS_USE_PKG_CONFIG, ZSTD_SYS_USE_PKG_CONFIG),
# so packages that vendored those libraries fail until they gain the inputs.
# audit-review: Check each package's system-library inputs or build independently on the locked channel.
_: final: prev:
let
  withInputs =
    {
      nativeBuildInputs ? [ ],
      buildInputs ? [ ],
    }:
    package:
    package.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ nativeBuildInputs;
      buildInputs = (old.buildInputs or [ ]) ++ buildInputs;
    });
in
{
  # https://github.com/NixOS/nixpkgs/pull/585086
  anyrun = withInputs { buildInputs = [ final.aws-lc ]; } prev.anyrun;

  # https://github.com/NixOS/nixpkgs/pull/585208, merged to master.
  ncspot = withInputs { buildInputs = [ final.aws-lc ]; } prev.ncspot;

  # No upstream fix yet. CMake links taskchampion's Rust static library
  # without -lsqlite3, so keep the bundled sqlite.
  taskwarrior3 = prev.taskwarrior3.overrideAttrs { dontCargoUseSystemLibs = true; };

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_pythonFinal: pythonPrev: {
      # https://github.com/NixOS/nixpkgs/pull/584300, merged to master.
      tree-sitter-language-pack = withInputs {
        nativeBuildInputs = [ final.pkg-config ];
        buildInputs = [ final.zstd ];
      } pythonPrev.tree-sitter-language-pack;
    })
  ];
}
