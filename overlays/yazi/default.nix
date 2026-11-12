_: _final: prev: {
  yaziPlugins = prev.yaziPlugins // {
    duckdb = prev.yaziPlugins.duckdb.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./duckdb-compat.patch ];
    });

    yatline = prev.yaziPlugins.yatline.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace main.lua \
          --replace-fail 'rt.term.light' 'rt.term.light()'
      '';
    });
  };
}
