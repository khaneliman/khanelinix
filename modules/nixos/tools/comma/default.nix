{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.tools.comma;
in
{
  options.khanelinix.tools.comma = {
    enable = mkBoolOpt false "Whether or not to enable comma.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      comma
      khanelinix.nix-update-index
    ];

    khanelinix.home.extraOptions = {
      programs.nix-index.enable = true;
    };
  };
}
