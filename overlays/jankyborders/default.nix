_: _final: prev: {
  # TODO: remove after hits channel
  jankyborders = prev.jankyborders.overrideAttrs (_oldAttrs: rec {
    version = "1.8.4";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "jankyborders";
      tag = "v${version}";
      hash = "sha256-31Er+cUQNJbZnXKC6KvlrBhOvyPAM7nP3BaxunAtvWg=";
    };
  });
}
