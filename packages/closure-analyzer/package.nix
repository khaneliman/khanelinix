{
  lib,
  python3Packages,
  ...
}:

python3Packages.buildPythonApplication rec {
  pname = "closure-analyzer";
  version = "0.1.0";

  format = "other";

  src = ./closure-analyzer.py;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/closure-analyzer
    chmod +x $out/bin/closure-analyzer
  '';

  meta = {
    description = "Analyze Nix closure size and identify optimization opportunities";
    longDescription = ''
      A comprehensive tool for analyzing Nix closure sizes, identifying large dependencies,
      and providing optimization suggestions. Particularly useful for WSL environments
      where closure size matters for performance and storage.

      Features:
      - Total closure size analysis
      - Identification of largest packages
      - Dependency chain analysis
      - Package categorization
      - WSL-specific optimization suggestions
      - JSON output for automation


      Example
      nix run .#closure-analyzer -- '.#nixosConfigurations.VT0-IT-47-D443.config.system.build.toplevel' --threshold 0.5
      nix run .#closure-analyzer -- '.#nixosConfigurations.VT0-IT-47-D443.config.system.build.toplevel' --threshold 0.5 --no-build
    '';
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.unix;
    mainProgram = "closure-analyzer";
  };
}
