{
  stdenvNoCC,
}:
args@{
  installPhase ? null,
  ...
}:
stdenvNoCC.mkDerivation (
  args
  // {
    installPhase =
      if installPhase != null then
        installPhase
      else
        ''
          runHook preInstall

          cp -r . $out

          runHook postInstall
        '';
  }
)
