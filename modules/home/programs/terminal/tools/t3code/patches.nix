{ pkgs }:
let
  fetchPatch =
    {
      name,
      rev ? null,
      url ? "https://github.com/khaneliman/t3code/commit/${rev}.patch",
      hash,
      excludes ? [ ],
    }:
    pkgs.fetchpatch2 {
      name = "t3code-${name}.patch";
      inherit excludes hash;
      inherit url;
    };
  # Ordering matters: later patches depend on earlier context, so a locally
  # rebased patch stays at its original position instead of moving to the tail.
  mkPatch = spec: spec.path or (fetchPatch spec);
in
(map mkPatch [
  # Perf pair rebased onto upstream 9e201941a on branch
  # nix-patches/perf-rebase-9e201941 (command-resolution reworked around
  # upstream's new PATH-resolution cache). Command resolution was rebased
  # again onto upstream 504177797 on branch nix-patches/perf-rebase-50417779,
  # where the file-manager probe became resolveUsableFileManagerCommand.
  {
    name = "perf-lazy-load-terminal-drawer";
    rev = "bf5a88adcad1e0e06cf563b348b366f3c868bf95";
    hash = "sha256-I5HT/NBkGuyj2uhlmTbnIkR78XAD48tEBb+vDDZ55q8=";
  }
  {
    name = "perf-concurrent-command-resolution";
    rev = "9d8723a7ca8e89e001f70d844331a19c9c520893";
    hash = "sha256-Y2d4QA8G9B1sxRpmvQkOrVDgsco2O6owkI+H76rghUI=";
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
    hash = "sha256-BD6S3vMsj77K1XKK+YwqRcYEXBkfhxskNddNVIQZs4w=";
    excludes = [ "apps/server/src/provider/Layers/ProviderInstanceRegistryLive.test.ts" ];
  }
  {
    # Upstream dropped AVAILABLE_PROVIDER_OPTIONS from providerIconUtils.ts,
    # which broke the fork commit's import hunk. Carried locally until the
    # fork branch is rebased.
    path = ./antigravity-provider-controls.patch;
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
    # The preceding stability patch omits this test file, so omit the
    # follow-up test hunk that depends on its excluded context.
    name = "antigravity-model-discovery";
    rev = "4b99a47b7a0e176d98f9e2cdd2d20bba2a94fa35";
    hash = "sha256-iWsXHUWzMVbkwai/1E9sUk546uE6LmuDjPbm7DnJMOI=";
    excludes = [ "apps/server/src/provider/Layers/AntigravityAdapter.test.ts" ];
  }
  {
    # Upstream added its own isCustom filter to mergeProviderModels. This
    # carries the merged form: cached custom rows and Antigravity name
    # duplicates are both dropped.
    path = ./antigravity-deduplicate-cached-models.patch;
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
])
++ [
  # PR #7507 has seven commits. This aggregate excludes its integration-test
  # hunks and refreshes the duplicate-event guard for upstream child metadata.
  ./fix-codex-spawned-subagent-sidebar.patch
  ./antigravity-planner-response.patch
  ./antigravity-conversation-discovery.patch
  ./antigravity-tool-result-projection.patch
  ./antigravity-subagent-projection.patch
  ./antigravity-skill-discovery.patch
  ./declarative-theme-settings.patch
]
