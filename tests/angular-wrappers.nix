{
  nixpkgs,
  root ? ../.,
}:
let
  pkgs = import nixpkgs { system = builtins.currentSystem; };
  # Keep a reintroduced hook observable without starting a real daemon.
  eslintProbe = pkgs.writeShellScriptBin "eslint_d" ''
    printf '%s\n' "$*" >> "$ESLINT_CALLS"
    exit 97
  '';
  shell = pkgs.callPackage (root + "/templates/angular/shell.nix") {
    eslint_d = eslintProbe;
  };
in
{
  packages =
    builtins.filter (
      p:
      builtins.elem p.name [
        "ng"
        "tsc"
        "typescript-lsp"
      ]
    ) shell.nativeBuildInputs
    ++ [
      pkgs.bash
      pkgs.nodejs
      eslintProbe
    ];
  rendered = {
    shellHook = shell.shellHook or "";
    bash = "${pkgs.bash}/bin/bash";
    runtimePath = pkgs.lib.makeBinPath [
      eslintProbe
      pkgs.nodejs
      pkgs.bash
    ];
  };
}
