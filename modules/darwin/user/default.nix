{ lib
, config
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.user;
in
{
  options.khanelinix.user = {
    name = mkOpt types.str "khaneliman" "The user account.";

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

      shell = pkgs.zsh;
    };

    khanelinix.home = {
      extraOptions.home.shellAliases = {
        nixre = "darwin-rebuild switch --flake .";
      };
    };
  };
}
