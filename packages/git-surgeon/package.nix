{
  lib,
  rustPlatform,
  fetchFromGitHub,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "git-surgeon";
  version = "0.1.14";

  src = fetchFromGitHub {
    owner = "raine";
    repo = "git-surgeon";
    rev = "v${version}";
    hash = "sha256-5Ac4pdxB8FJbGGNc+gi+E+KHQgur3DTeF1IpboYdQJA=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  meta = {
    description = "Surgical git hunk control for AI agents";
    homepage = "https://github.com/raine/git-surgeon";
    changelog = "https://github.com/raine/git-surgeon/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ khaneliman ];
    platforms = lib.platforms.all;
    mainProgram = "git-surgeon";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
