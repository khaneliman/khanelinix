{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools._1password-cli;
in
{
  options.khanelinix.programs.terminal.tools._1password-cli = {
    enable = lib.mkEnableOption "1password-cli";
    enableSshSocket = lib.mkEnableOption "ssh-agent socket";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age-plugin-1p
      _1password-cli
    ];

    programs = {
      ssh.extraConfig = lib.optionalString cfg.enableSshSocket ''
        Host *
          AddKeysToAgent yes
          IdentityAgent ${config.home.homeDirectory}/.1password/agent.sock
      '';
    };
  };
}
