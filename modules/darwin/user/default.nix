{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf getExe;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.user;
in
{
  options.khanelinix.user = {
    name = mkOpt types.str "khaneliman" "The user account.";
    email = mkOpt types.str "khaneliman12@gmail.com" "The email of the user.";
    fullName = mkOpt types.str "Austin Horstman" "The full name of the user.";
    uid = mkOpt (types.nullOr types.int) 501 "The uid for the user account.";
  };

  config = {
    users.users.${cfg.name} = {
      uid = mkIf (cfg.uid != null) cfg.uid;
      shell = pkgs.zsh;

      openssh = {
        authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpfTVxQKmkAYOrsnroZoTk0LewcBIC4OjlsoJY6QbB0"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBG8l3jQ2EPLU+BlgtaQZpr4xr97n2buTLAZTxKHSsD"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7UBwfd7+K0mdkAIb2TE6RzMu6L4wZnG/anuoYqJMPB"
        ];
      };
    };

    khanelinix.home = {
      extraOptions.home.shellAliases = {
        nixre = "darwin-rebuild switch --flake .";
        gsed = "${getExe pkgs.gnused}";
      };
    };
  };
}
