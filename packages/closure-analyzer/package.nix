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
      - Total closure size analysis with both actual and dependency-inclusive sizes
      - Identification of largest packages and dependency burden analysis
      - Package categorization with 15+ predefined categories
      - Comparison with previous analyses via caching
      - WSL-specific optimization suggestions
      - Enhanced JSON output for automation and CI integration
      - Robust error handling and timeout protection
      - Batch processing to handle large closures efficiently

      Example Usage:
        # Analyze a NixOS system
        nix run .#closure-analyzer -- '.#nixosConfigurations.myhost.config.system.build.toplevel'
        
        # Set custom threshold for "large" packages
        nix run .#closure-analyzer -- '.#nixosConfigurations.myhost.config.system.build.toplevel' --threshold 0.5
        
        # Skip building if result already exists
        nix run .#closure-analyzer -- '.#nixosConfigurations.myhost.config.system.build.toplevel' --no-build
        
        # Generate JSON output for CI/automation
        nix run .#closure-analyzer -- '.#nixosConfigurations.myhost.config.system.build.toplevel' --json
        
        # Compare with previous run
        nix run .#closure-analyzer -- '.#nixosConfigurations.myhost.config.system.build.toplevel' --compare-only
        
        # Save report to file
        nix run .#closure-analyzer -- '.#nixosConfigurations.myhost.config.system.build.toplevel' -o report.txt
    '';
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.unix;
    mainProgram = "closure-analyzer";
  };
}
