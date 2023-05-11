{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.fastfetch;
in
{
  options.khanelinix.cli-apps.fastfetch = with types; {
    enable = mkBoolOpt false "Whether or not to enable fastfetch.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ nur.repos.vanilla.fastfetch ];

    khanelinix.home = {
      configFile = with inputs;{
        "fastfetch/".source = dotfiles.outPath + "/dots/shared/home/.config/fastfetch";
      };
      file = {
        ".local/share/fastfetch/presets/local-overrides".source = ./local-overrides;
      };
    };
  };
}
