{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.fastfetch;
in
{
  options.khanelinix.cli-apps.fastfetch = with types; {
    enable = mkBoolOpt false "Whether or not to enable fastfetch.";
    local-overrides = mkOpt str "" "Local overrides to add to configuration.";
  };

  config = mkIf cfg.enable {
    xdg.configFile."fastfetch" = {
      source = lib.cleanSourceWith {
        src = lib.cleanSource ./config/.;
      };

      recursive = true;
    };

    home.file = {
      ".local/share/fastfetch/presets/local-overrides".text =
        lib.optionalString pkgs.stdenv.isDarwin ''
          --os-key " \e[32m ├─ "
          --packages-key " \e[32m ├─ "
          --kernel-key " \e[32m ├─ "
        ''
        + lib.optionalString pkgs.stdenv.isLinux ''
        ''
        + cfg.local-overrides;

    };
  };
}
