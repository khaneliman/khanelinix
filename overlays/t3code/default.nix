_: _final: prev: {
  t3code = prev.t3code.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch2 {
        name = "t3code-pr-2849-claude-opus-4-8.patch";
        url = "https://github.com/pingdotgg/t3code/pull/2849.patch";
        hash = "sha256-IWgKwgNqhd51jvzRxz6r5fPaqa60KutR6ed9T1xLPTw=";
      })
    ];
  });
}
