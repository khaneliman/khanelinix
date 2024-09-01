{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  system,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (inputs) nix-ld-rs;

  cfg = config.${namespace}.programs.terminal.tools.nix-ld;
in
{
  options.${namespace}.programs.terminal.tools.nix-ld = {
    enable = mkBoolOpt false "Whether or not to enable nix-ld.";
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      package = nix-ld-rs.packages.${system}.nix-ld-rs;

      libraries = with pkgs; [
        gcc
        icu
        libcxx
        stdenv.cc.cc.lib
        zlib
      ];
    };
  };
}
