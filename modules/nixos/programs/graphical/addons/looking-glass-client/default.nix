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
  inherit (config.${namespace}) user;

  cfg = config.${namespace}.programs.graphical.addons.looking-glass-client;
in
{
  options.${namespace}.programs.graphical.addons.looking-glass-client = {
    enable = mkBoolOpt false "Whether or not to enable the Looking Glass client.";
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

    systemd.tmpfiles.settings = {
      "looking-glass" = {
        "/dev/shm/looking-glass".f = {
          age = "-";
          group = "kvm";
          mode = "0660";
          user = toString config.users.users.${user.name}.uid;
        };
      };
    };
  };
}
