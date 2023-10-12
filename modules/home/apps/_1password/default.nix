{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps._1password;
in
{
  options.khanelinix.apps._1password = {
    enable = mkBoolOpt false "Whether or not to enable 1password.";
  };

  config = mkIf cfg.enable {
    programs = {
      ssh.extraConfig = ''
        Host *
          AddKeysToAgent yes
          IdentityAgent ~/.1password/agent.sock
      '';
    };
  };
}
