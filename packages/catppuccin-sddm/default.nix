{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "sddm-catppuccin";
  version = "unstable-2022-4-21";

  src = fetchFromGitHub {
    owner = "khaneliman";
    repo = "sddm-catppuccin";
    rev = "7b7a86ee9a5a2905e7e6623d2af5922ce890ef79";
    hash = "sha256-sTnt8RarNXz3RmYfmx4rD+nMlY8rr2n0EN3ntPzOurw=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/sddm/themes/"
    cp -r catppuccin/ "$out/share/sddm/themes/"
    runHook postInstall
  '';

  meta = {
    description = "Soothing pastel theme for SDDM";
    homepage = "https://github.com/khaneliman/sddm-catppuccin";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [khaneliman];
    platforms = lib.platforms.linux;
  };
}
