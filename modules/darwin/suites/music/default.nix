{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.music;
in
{
  options.${namespace}.suites.music = {
    enable = mkBoolOpt false "Whether or not to enable music configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      spicetify-cli
      # TODO: replace? don't use and marked insecure
      # youtube-dl
    ];

    homebrew = {
      casks = [ "spotify" ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable { "GarageBand" = 682658836; };
    };
  };
}
