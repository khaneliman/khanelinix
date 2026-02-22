{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.programs.graphical.apps._1password;
in
{
  options.khanelinix.programs.graphical.apps._1password = {
    enable = lib.mkEnableOption "1password";
    enableSshSocket = lib.mkEnableOption "ssh-agent socket";
  };

  config = mkIf cfg.enable {
    programs = {
      _1password = enabled;
      _1password-gui = {
        # 1Password documentation
        # See: https://support.1password.com/
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
