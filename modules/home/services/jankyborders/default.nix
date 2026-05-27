{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.jankyborders;
  userHome = config.home.homeDirectory;
in
{
  options.khanelinix.services.jankyborders = {
    enable = lib.khanelinix.mkBoolOpt false "Whether to enable jankyborders in the desktop environment.";
  };

  config = mkIf cfg.enable {
    home.activation.jankybordersTccShim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo >&2 "Setting up stable TCC shim for jankyborders..."
      $DRY_RUN_CMD mkdir -p "${userHome}/.local/bin"
      # We must copy, not symlink, so TCC sees a stable filesystem path.
      if [[ ! -e "${userHome}/.local/bin/borders-stable" ]] || ! cmp -s "${pkgs.jankyborders}/bin/borders" "${userHome}/.local/bin/borders-stable"; then
        $DRY_RUN_CMD cp -f "${pkgs.jankyborders}/bin/borders" "${userHome}/.local/bin/borders-stable"
        $DRY_RUN_CMD chmod +x "${userHome}/.local/bin/borders-stable"
      fi
    '';

    launchd.agents.jankyborders.config.ProgramArguments = lib.mkForce [
      "${userHome}/.local/bin/borders-stable"
    ];

    services.jankyborders = {
      # Jankyborders documentation
      # See: https://github.com/FelixKratz/JankyBorders
      enable = true;

      settings = {
        style = "round";
        width = 6.0;
        hidpi = "off";
        # AeroSpace modifies window state, so use AX-backed focus resolution
        # for better border/focus consistency.
        ax_focus = "on";
        active_color = "0xff7793d1";
        inactive_color = "0xff5e6798";
        # FIXME: broken atm
        # background_color = "0x302c2e34";
      };
    };
  };
}
