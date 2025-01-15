{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools._1password-cli;
in
{
  options.khanelinix.programs.terminal.tools._1password-cli = {
    enable = mkBoolOpt false "Whether or not to enable 1password-cli.";
    enableSshSocket = mkBoolOpt false "Whether or not to enable ssh-agent socket.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs._1password-cli ];

    programs = {
      ssh.extraConfig = lib.optionalString cfg.enableSshSocket ''
        Host *
          AddKeysToAgent yes
          IdentityAgent ~/.1password/agent.sock
      '';
    };
  };
}
