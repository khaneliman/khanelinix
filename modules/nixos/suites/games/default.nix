{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkDefault;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.games;
in
{
  options.${namespace}.suites.games = {
    enable = lib.mkEnableOption "common games configuration";
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
