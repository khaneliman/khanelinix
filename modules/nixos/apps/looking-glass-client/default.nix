{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.looking-glass-client;
  inherit (config.khanelinix) user;
in
{
  options.khanelinix.apps.looking-glass-client = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable the Looking Glass client.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      looking-glass-client
      obs-studio-plugins.looking-glass-obs
    ];

    environment.etc."looking-glass-client.ini" = {
      user = "+${toString config.users.users.${user.name}.uid}";
      source = ./client.ini;
    };
  };
}
