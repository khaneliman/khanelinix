_: _final: prev: {
  sketchybar-app-font = prev.sketchybar-app-font.overrideAttrs rec {
    version = "2.0.42";

    src = prev.fetchFromGitHub {
      owner = "kvndrsslr";
      repo = "sketchybar-app-font";
      tag = "v${version}";
      hash = "sha256-ERYbwtOmMKJNnp4Gn35dbjukFpcD8t1GjI7eDXubAjo=";
    };

    pnpmDeps = prev.pnpm_9.fetchDeps {
      pname = "test";
      inherit src version;
      fetcherVersion = 1;
      hash = "sha256-ZdcXBrtxxdi8+w3fXN31fFIsHcPAVhfthhDRWNmaKoc=";
    };
  };
}
