{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.programs.graphical.apps._1password;
in
{
  options.khanelinix.programs.graphical.apps._1password = {
    enable = mkBoolOpt false "Whether or not to enable 1password.";
    enableSshSocket = mkBoolOpt false "Whether or not to enable ssh-agent socket.";
  };

  config = mkIf cfg.enable {
    programs = {
      _1password = enabled;
      _1password-gui = {
        enable = true;
        package = pkgs._1password-gui;

        polkitPolicyOwners = [ config.khanelinix.user.name ];
      };

      ssh.extraConfig = lib.optionalString cfg.enableSshSocket ''
        Host *
          AddKeysToAgent yes
          IdentityAgent ~/.1password/agent.sock
      '';
    };
  };
}
