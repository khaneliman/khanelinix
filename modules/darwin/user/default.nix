{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.user;
in
{
  options.khanelinix.user = {
    name = mkOpt (types.nullOr types.str) null "The user account.";
    email = mkOpt types.str "" "The email of the user.";
    fullName = mkOpt types.str "" "The full name of the user.";
    uid = mkOpt (types.nullOr types.int) 501 "The uid for the user account.";
  };

  config = lib.mkIf (cfg.name != null) {
    users.users.${cfg.name} = {
      uid = mkIf (cfg.uid != null) cfg.uid;
      shell = pkgs.zsh;
      home = "/Users/${cfg.name}";
    };
  };
}
