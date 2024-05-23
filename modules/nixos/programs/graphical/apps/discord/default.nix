{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.apps.discord;
in
{
  options.${namespace}.programs.graphical.apps.discord = {
    enable = mkBoolOpt false "Whether or not to enable Discord.";
    canary.enable = mkBoolOpt false "Whether or not to enable Discord Canary.";
    firefox.enable = mkBoolOpt false "Whether or not to enable the Firefox version of Discord.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      lib.optional cfg.enable pkgs.discord
      ++ lib.optional cfg.canary.enable pkgs.${namespace}.discord
      ++ lib.optional cfg.firefox.enable pkgs.${namespace}.discord-firefox;

    system.userActivationScripts = {
      postInstall = # bash
        ''
          echo "Running betterdiscord install"
          source ${config.system.build.setEnvironment}
          ${getExe pkgs.betterdiscordctl} install || true
        '';
    };
  };
}
