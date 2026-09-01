{
  lib,
  fetchFromGitHub,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "jj-hunk-tool";
  version = "0-unstable-2026-07-19";

  src = fetchFromGitHub {
    owner = "mvzink";
    repo = "jj-hunk-tool";
    rev = "066ff0a6b959472c9bf6ae3a652ef6d367f27e1a";
    hash = "sha256-h/0vMBGrY9zBb6K+l4b+4Eos5Z16TA/3l8jkUzAIfyw=";
  };

  cargoHash = "sha256-qH/R0+urKZX3qtD6wt42hjgBOtu170HaR3SegRNlkh4=";

  # FIXME: upstream integration tests depend on a richer local jj/git environment and
  # fail in nix sandboxed builds; disable checks to keep install working.
  doCheck = false;

  meta = {
    description = "Hunk-level Jujutsu tooling for AI-assisted workflows";
    homepage = "https://github.com/mvzink/jj-hunk-tool";
    changelog = "https://github.com/mvzink/jj-hunk-tool/commits/main";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ khaneliman ];
    mainProgram = "jj-hunk-tool";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
