{ config
, lib
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
    home.packages = with pkgs; [
      comma
      khanelinix.nix-update-index
    ];

    programs.nix-index = {
      enable = true;
      package = pkgs.nix-index;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };
  };
}
