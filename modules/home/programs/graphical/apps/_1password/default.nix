{
  config,
  lib,
  namespace,
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
