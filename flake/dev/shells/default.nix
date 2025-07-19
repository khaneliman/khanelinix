{
  inputs,
  mkShell,
  pkgs,
  system,
  ...
}:
mkShell {
  packages = with pkgs; [
    act
    deadnix
    nh
    statix
    sops
    (inputs.treefmt-nix.lib.mkWrapper pkgs ../../treefmt.nix)
  ];

  shellHook = ''
    ${inputs.self.checks.${system}.pre-commit-hooks.shellHook}
    echo 🔨 Welcome to Khanelinix! 


  '';
}
