{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkDefault;
  inherit (lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.games;
in
{
  options.khanelinix.suites.games = {
    enable = mkBoolOpt false "Whether or not to enable common games configuration.";
  };

  config = lib.mkIf cfg.enable {
    khanelinix = {
      programs = {
        graphical = {
          addons = {
            gamemode = mkDefault enabled;
            gamescope = mkDefault enabled;
            # mangohud = mkDefault enabled;
          };

          apps = {
            steam = mkDefault enabled;
          };
        };
      };

      services.flatpak.extraPackages = [
        {
          # Sober for Roblox
          flatpakref = "https://sober.vinegarhq.org/sober.flatpakref";
          sha256 = "sha256:1pj8y1xhiwgbnhrr3yr3ybpfis9slrl73i0b1lc9q89vhip6ym2l";
        }
      ];
    };
  };
}
