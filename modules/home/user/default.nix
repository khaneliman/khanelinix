{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) types mkIf mkDefault mkMerge;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.user;
  is-darwin = pkgs.stdenv.isDarwin;

  home-directory =
    if cfg.name == null
    then null
    else if is-darwin
    then "/Users/${cfg.name}"
    else "/home/${cfg.name}";
in {
  options.khanelinix.user = {
    enable = mkOpt types.bool false "Whether to configure the user account.";
    name = mkOpt (types.nullOr types.str) config.snowfallorg.user.name "The user account.";

    fullName = mkOpt types.str "Austin Horstman" "The full name of the user.";
    email = mkOpt types.str "khaneliman12@gmail.com" "The email of the user.";

    home = mkOpt (types.nullOr types.str) home-directory "The user's home directory.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.name != null;
          message = "khanelinix.user.name must be set";
        }
        {
          assertion = cfg.home != null;
          message = "khanelinix.user.home must be set";
        }
      ];

      home = {
        username = mkDefault cfg.name;
        homeDirectory = mkDefault cfg.home;
      };
    }
  ]);
}
