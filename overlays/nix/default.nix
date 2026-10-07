_: _final: prev: {
  nixVersions = prev.nixVersions // {
    # Nix sends access-tokens only to api.github.com, whose tarball endpoint
    # redirects to codeload.github.com. curl drops the token on that redirect,
    # so flake updates hit GitHub's anonymous per-network 429 limit. Drop this
    # once upstream Nix authenticates the codeload download.
    latest = (prev.nixVersions.latest.appendPatches [ ./github-codeload-auth.patch ]).overrideAttrs {
      # The recursive-nix functional test stats the host's root channel
      # profile. Darwin's sandbox denies reads outside the build closure,
      # so the test fails with EPERM on hosts that have a root channel.
      doCheck = !prev.stdenv.hostPlatform.isDarwin;
    };
  };
}
