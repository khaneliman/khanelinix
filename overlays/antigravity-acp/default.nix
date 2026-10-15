{ inputs }:
final: prev:
let
  package =
    prev.antigravity-acp
      or (final.callPackage "${inputs.nixpkgs-unstable}/pkgs/by-name/an/antigravity-acp/package.nix" { });
in
{
  antigravity-acp = package.overrideAttrs (old: {
    # Stripping removes the Python archive appended to the executable.
    dontStrip = true;
    doInstallCheck = final.stdenv.hostPlatform.isDarwin;
    nativeInstallCheckInputs = (old.nativeInstallCheckInputs or [ ]) ++ [ final.python3 ];
    installCheckPhase = ''
      runHook preInstallCheck
      python ${./check-initialize.py} "$out/bin/agy_acp_server.par"
      runHook postInstallCheck
    '';
  });
}
