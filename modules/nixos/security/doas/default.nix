{
  config,
  lib,
  namespace,
  ...
}:
let

  cfg = config.${namespace}.security.doas;
in
{
  options.${namespace}.security.doas = {
    enable = lib.mkEnableOption "replacing sudo with doas";
  };

  config = lib.mkIf cfg.enable {
    # Add an alias to the shell for backward-compat and convenience.
    environment.shellAliases = {
      sudo = "doas";
    };

    # Disable sudo
    security.sudo.enable = false;

    # Enable and configure `doas`.
    security.doas = {
      enable = true;

      extraRules = [
        {
          keepEnv = true;
          noPass = true;
          users = [ config.${namespace}.user.name ];
        }
      ];
    };
  };
}
