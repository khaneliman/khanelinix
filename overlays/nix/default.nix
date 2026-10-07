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

  # nixd links the Nix libraries but does not need the codeload fix. Keep the
  # family on upstream Nix so it comes from the binary cache; a local rebuild
  # runs nixt's tests, which fail on darwin for the same root channel reason.
  nixd = prev.nixd.override { inherit (prev) nixVersions; };
  nixf = prev.nixf.override { inherit (prev) nixVersions; };
  nixt = prev.nixt.override { inherit (prev) nixVersions; };
}
