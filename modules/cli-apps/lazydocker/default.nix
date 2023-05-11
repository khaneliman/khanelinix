{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.lazydocker;
in
{
  options.khanelinix.cli-apps.lazydocker = with types; {
    enable = mkBoolOpt false "Whether or not to enable lazydocker.";
  };

  config =
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ lazydocker ];
      khanelinix.home = {
        extraOptions = {
          home.shellAliases = {
            # #
            # Docker aliases
            # #
            dcu = "docker-compose up -d";
            dcd = "docker-compose down";
            dim = "docker images";
            dps = "docker ps";
            dpsa = "docker ps -a";
            dsp = "docker system prune --all";
          };
        };
      };
    };
}
