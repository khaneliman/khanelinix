{
  callPackage,
  writeShellScriptBin,
  eslint_d,
  prettierd,
}:
let
  mainPkg = callPackage ./default.nix { };
  mkLocalAlias =
    name: args:
    writeShellScriptBin name ''
      if [ ! -x ./node_modules/.bin/tsc ]; then
        echo "Run npm ci from the project root before using ${name}." >&2
        exit 1
      fi
      exec ./node_modules/.bin/tsc ${args} "$@"
    '';
in
mainPkg.overrideAttrs (oa: {
  nativeBuildInputs = [
    eslint_d
    prettierd
    (mkLocalAlias "tsc" "")
    (mkLocalAlias "typescript-lsp" "--lsp")
  ]
  ++ (oa.nativeBuildInputs or [ ]);
})
