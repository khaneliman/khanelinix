{
  lib,
  fetchFromGitHub,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "jj-hunk-tool";
  version = "0-unstable-2026-09-18";

  src = fetchFromGitHub {
    owner = "mvzink";
    repo = "jj-hunk-tool";
    rev = "817a3d19cab8ed9bf04ebf64f2f3073fe195d641";
    hash = "sha256-HtuR2IL/WIq6+y8saHFAyquQ8cFGvvz0t3VqZXBQ7gI=";
  };

  cargoHash = "sha256-ncpm8g5In2Ih5cx3AnG2vPfGFy5oMnR012hBKqV4fYw=";

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
