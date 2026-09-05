_: _final: prev: {
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
