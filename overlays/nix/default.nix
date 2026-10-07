_: _final: prev: {
  nixVersions = prev.nixVersions // {
    # Nix sends access-tokens only to api.github.com, whose tarball endpoint
    # redirects to codeload.github.com. curl drops the token on that redirect,
    # so flake updates hit GitHub's anonymous per-network 429 limit. Drop this
    # once upstream Nix authenticates the codeload download.
    latest = prev.nixVersions.latest.appendPatches [ ./github-codeload-auth.patch ];
  };
}
