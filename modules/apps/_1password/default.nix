{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps._1password;
in
{
  options.khanelinix.apps._1password = with types; {
    enable = mkBoolOpt false "Whether or not to enable 1password.";
  };

  config = mkIf cfg.enable {
    programs = {
      _1password = enabled;
      _1password-gui = {
        enable = true;

        polkitPolicyOwners = [ config.khanelinix.user.name ];
      };

      ssh.extraConfig = ''
        Host *
          AddKeysToAgent yes
          IdentityAgent ~/.1password/agent.sock
      '';
    };

    system.activationScripts.postInstall1Password = stringAfter [ "users" ] ''
      echo "Running command after 1Password installation"
      mkdir -p /opt/1Password/
      ln -sf ${./op-ssh-sign} /opt/1Password/op-ssh-sign
    '';
  };
}
