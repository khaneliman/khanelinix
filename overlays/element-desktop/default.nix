_: _final: prev: {
  # FIXME: broken nixpkgs latest version
  # https://github.com/NixOS/nixpkgs/issues/485589
  element-desktop = prev.element-desktop.overrideAttrs (
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin rec {
      # buildInputs = [ prev.apple-sdk_26 ];

      version = "1.12.8";

      src = prev.fetchFromGitHub {
        owner = "element-hq";
        repo = "element-desktop";
        tag = "v1.12.8";
        hash = "sha256-J+ITqHLxbmhhjFnyfBlHFzxrPeIvsCv+iaxa8DiWorM=";
      };

      offlineCache = prev.fetchYarnDeps {
        yarnLock = src + "/yarn.lock";
        hash = "sha256-coa2AMNGLDtqcrQJDc/DDkcaWBCLa76VTKJLGlr7dpQ=";
      };
    }
  );
}
