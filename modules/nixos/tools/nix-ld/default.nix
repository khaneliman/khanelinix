{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.tools.nix-ld;
in
{
  options.khanelinix.tools.nix-ld = {
    enable = mkBoolOpt false "Whether or not to enable nix-ld.";
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;

      libraries = with pkgs; [
        gcc
        clang
        cmake
        libcxx
        gnumake
        meson
        pkg-config
      ];
    };
  };
}
