{
  callPackage,
  writeShellScriptBin,
  eslint_d,
  prettierd,
}:
let
  mainPkg = callPackage ./default.nix { };
  mkLocalAlias =
    name: binary: args:
    writeShellScriptBin name ''
      if [ ! -x ./node_modules/.bin/${binary} ]; then
        echo "Run npm ci from the project root before using ${name}." >&2
        exit 1
      fi
      exec ./node_modules/.bin/${binary} ${args} "$@"
    '';
in
mainPkg.overrideAttrs (oa: {
  nativeBuildInputs = [
    eslint_d
    prettierd
    (mkLocalAlias "tsc" "tsc" "")
    (mkLocalAlias "typescript-lsp" "tsc" "--lsp")
    (mkLocalAlias "ng" "ng" "")
  ]
  ++ (oa.nativeBuildInputs or [ ]);
})
