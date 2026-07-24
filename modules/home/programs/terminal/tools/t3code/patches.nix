{ pkgs }:
let
  fetchPatch =
    {
      name,
      rev,
      hash,
      excludes ? [ ],
    }:
    pkgs.fetchpatch2 {
      name = "t3code-${name}.patch";
      url = "https://github.com/khaneliman/t3code/commit/${rev}.patch";
      inherit excludes hash;
    };
in
map fetchPatch [
  {
    name = "perf-lazy-load-terminal-css";
    rev = "904f535940872e21f59f10f12e545ac9e894e713";
    hash = "sha256-D++ggKNE0ZvOAw6IHmeQ67FHD31ELs3FOb1+F0lU1GQ=";
  }
  {
    name = "perf-lazy-load-terminal-drawer";
    rev = "fe4d23ee916229041308d1b8ce6de9abefcb919e";
    hash = "sha256-PfIeQA6Ma08UJegG9Vhx9G0gVxLysVMUK30P6yHwH9o=";
  }
  {
    name = "perf-concurrent-command-resolution";
    rev = "ef44192d8c7d1a58b3197b647f823903a316c176";
    hash = "sha256-Mj8xqESbCEFevkqytSr/BQBwKs1qLEtTET44aVicSd8=";
  }
  {
    name = "perf-desktop-readiness-probe-timeout";
    rev = "8063dd0634ca781725db593f619dda849bbe733b";
    hash = "sha256-mBf/gdIFKoGztmUwlXfAGw7BJ4XqvJk5yhSVY4bfi94=";
  }
  # Antigravity stack: rebased onto upstream 9cbe50d10 on branch
  # nix-patches/antigravity-rebase (docs commit dropped).
  {
    name = "antigravity-provider-settings";
    rev = "3f4511a636bf6b152a6419661cc5d3f45588390b";
    hash = "sha256-EUnhYfOFuE/q64vvK4Kar9dxLlb5Y56zdiN5YeYgwlI=";
  }
  {
    name = "antigravity-provider-driver";
    rev = "0a8cd769ef3c0a536fc556449b38ad7d9a3b4d7a";
    hash = "sha256-RZBAu4ErgWgMjC7dyFKtMtKp/pwsYmZY/pBb+KXj1o0=";
  }
  {
    name = "antigravity-provider-controls";
    rev = "4a49d4c9cf9de81d53dd39e5275d6c06fd3d80a9";
    hash = "sha256-2FcLKLKCWQzVRvVWmTNBQqc7y668vdlkWUsEnjN+2VU=";
  }
  {
    name = "antigravity-cli-only-mode";
    rev = "70dd5053022a25533f2835929d5ee3576ca3b766";
    hash = "sha256-XVsfaXjm0uEE0yXLcNuZQwqwqVHuBuCvMgSXGgIymV4=";
  }
  {
    name = "antigravity-plan-mode";
    rev = "72c2203f85956ccd368238f6822338d59954b78a";
    hash = "sha256-TVcUZpRUb6/vauKHs4lBHNOVPaarlQJoPIp1v9vbm4I=";
  }
  {
    # Nixpkgs build runs no tests; keep only the runtime synchronous
    # initial-poll hunk.
    name = "antigravity-test-stability";
    rev = "88b66258e071117e08fff0def6abdd09100a0ddb";
    hash = "sha256-bkLFB7JEJWc+8KA2FcGYInEgjYqIdtH+tQavrSIlqSc=";
    excludes = [ "apps/server/src/provider/Layers/AntigravityAdapter.test.ts" ];
  }
  {
    name = "fix-codex-session-start-timeout";
    rev = "883b413cd9cfbb428abafc9f2a877ca14a9e6795";
    hash = "sha256-5b5mRry2OF120R0pAAVKXT9TG2nAes+ZQb848nyTrNQ=";
  }
  {
    # Test hunk drifts with upstream; runtime fix still absent upstream.
    name = "fix-agent-queue-blocked-on-session-start";
    rev = "2a504ad066bd5ec1413905f0f71e906180e8ee98";
    hash = "sha256-3p2Drn04OlrcfB8hQ7sCefjD5SPx3IALcqNkESwFt9I=";
    excludes = [ "apps/server/src/orchestration/Layers/ProviderCommandReactor.test.ts" ];
  }
]
