{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.nix-ld;
in
{
  options.${namespace}.programs.terminal.tools.nix-ld = {
    enable = mkBoolOpt false "Whether or not to enable nix-ld.";
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs;

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
