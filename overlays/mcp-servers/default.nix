{ inputs }:
final: prev:
prev.lib.genAttrs
  [
    "mcp-server-filesystem"
    "mcp-server-sequential-thinking"
  ]
  (
    name:
    inputs.mcp-servers-nix.packages.${final.stdenv.hostPlatform.system}.${name}.overrideAttrs (old: {
      # The packaged TypeScript compiler no longer includes Node globals implicitly.
      postPatch = (old.postPatch or "") + ''
        substituteInPlace tsconfig.json \
          --replace-fail '"compilerOptions": {' '"compilerOptions": { "types": ["node"],'
      '';
    })
  )
