{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.lazygit;
in
{
  options.khanelinix.cli-apps.lazygit = with types; {
    enable = mkBoolOpt false "Whether or not to enable lazygit.";
  };

  config =
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ lazygit ];
      khanelinix.home = {
        extraOptions = {
          home.shellAliases = {
            lg = "lazygit";
          };
        };
      };
    };
}
