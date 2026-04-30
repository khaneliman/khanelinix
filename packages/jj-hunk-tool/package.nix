{
  lib,
  fetchFromGitHub,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "jj-hunk-tool";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "mvzink";
    repo = "jj-hunk-tool";
    rev = "0fceafeb8d0907790e9fec327df768355b8748d4";
    hash = "sha256-XK6tAXlLUP0kI1UdyQB6ZLY3toRILmmKtQyJ0l4tyeQ=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

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
