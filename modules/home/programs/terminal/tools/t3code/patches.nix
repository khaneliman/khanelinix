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
    hash = "sha256-irCex6Wauqb4BKMR9MtM2FDExc+Opx9v4wVV87oUV4A=";
    excludes = [ "apps/web/src/components/ChatView.tsx" ];
  }
  # Upstream added animated terminal drawer presence around the component.
  # Keep that structure while applying the lazy import from the excluded hunk.
  {
    path = ./perf-lazy-load-terminal-drawer.patch;
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
  ./desktop-attach-existing-backend.patch
]
