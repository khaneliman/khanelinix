{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.apps._1password;
in
{
  options.${namespace}.programs.graphical.apps._1password = {
    enable = mkBoolOpt false "Whether or not to enable 1password.";
    enableSshSocket = mkBoolOpt false "Whether or not to enable ssh-agent socket.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs._1password-cli ];

    programs = {
      ssh.extraConfig = ''
        Host *
          AddKeysToAgent yes
          ${lib.optionalString cfg.enableSshSocket "IdentityAgent ~/.1password/agent.sock"}
      '';
    };
  };
}
