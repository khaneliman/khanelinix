{ lib, config, pkgs, ... }:

let
  inherit (lib) types mkIf mkDefault;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.user;

  is-linux = pkgs.stdenv.isLinux;
  is-darwin = pkgs.stdenv.isDarwin;
in
{
  options.khanelinix.user = {
    name = mkOpt types.str "short" "The user account.";

    fullName = mkOpt types.str "Austin Horstman" "The full name of the user.";
    email = mkOpt types.str "khaneliman12@gmail.com" "The email of the user.";

    uid = mkOpt (types.nullOr types.int) 501 "The uid for the user account.";
  };

  config = {
    users.users.${cfg.name} = {
      # @NOTE(jakehamilton): Setting the uid here is required for another
      # module to evaluate successfully since it reads
      # `users.users.${khanelinix.user.name}.uid`.
      uid = mkIf (cfg.uid != null) cfg.uid;
    };
  };
}
