{ inputs }:
_final: prev:
let
  pkgsMaster = import inputs.nixpkgs-master {
    inherit (prev.stdenv.hostPlatform) system;
    inherit (prev) config;
  };
in
{
  # Use master only until the primary package set carries this release.
  yazi = if prev.lib.versionAtLeast prev.yazi.version "26.8.15" then prev.yazi else pkgsMaster.yazi;

  yaziPlugins = prev.yaziPlugins // {
    duckdb = prev.yaziPlugins.duckdb.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./duckdb-compat.patch ];
    });

    yatline = prev.yaziPlugins.yatline.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace main.lua \
          --replace-fail 'hovered:icon()' 'th.icon:match(hovered)' \
          --replace-fail 'cwd.is_search' 'cwd.spec.is_search' \
          --replace-fail 'cwd.domain' 'cwd.spec.domain' \
          --replace-fail 'rt.term.light' 'rt.term.light()'
      '';
    });
  };
}
