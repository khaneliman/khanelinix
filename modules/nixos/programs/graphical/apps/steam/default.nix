{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) suiteProfileIncludes;

  cfg = config.khanelinix.programs.graphical.apps.steam;
  gamesCfg = config.khanelinix.suites.games;
  maximal = suiteProfileIncludes config gamesCfg "maximal";

  shortcutType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Library entry name. Entries are matched and replaced by name.";
      };
      exe = lib.mkOption {
        type = lib.types.str;
        description = "Absolute path of the program Steam launches.";
      };
      startDir = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Working directory. Defaults to the directory of `exe`.";
      };
      launchOptions = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Arguments appended after `exe`.";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Absolute path of an icon image.";
      };
      tags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Library collections the entry belongs to.";
      };
    };
  };

  shortcutsJson = pkgs.writers.writeJSON "steam-shortcuts.json" cfg.shortcuts;

  # Steam rewrites shortcuts.vdf on exit, so a symlink from the store would
  # be clobbered on first save. Instead merge managed entries into every
  # userdata profile right before the client starts, while Steam is not
  # running and cannot race the write.
  shortcutsSync = pkgs.writers.writePython3Bin "steam-shortcuts-sync" {
    libraries = [ pkgs.python3Packages.vdf ];
  } (builtins.readFile ./shortcuts-sync.py);
in
{
  options.khanelinix.programs.graphical.apps.steam = {
    enable = lib.mkEnableOption "support for Steam";

    shortcuts = lib.mkOption {
      type = lib.types.listOf shortcutType;
      default = [ ];
      description = ''
        Non-Steam programs kept in every Steam user's library. Managed entries
        are tagged and pruned when removed here; entries added through the
        Steam client are left alone.
      '';
    };
  };

  config = lib.mkMerge [
    {
      # Jovian's gamescope session execs pkgs.steam directly rather than
      # programs.steam.package, so the hook must live on the package itself to
      # cover Gaming Mode as well as desktop launches. The overlay is
      # unconditional and the body lazy: gating the list on cfg.shortcuts
      # would evaluate home-manager config while pkgs is still being fixed.
      nixpkgs.overlays = [
        (_final: prev: {
          steam = prev.steam.override (old: {
            extraPreBwrapCmds =
              (old.extraPreBwrapCmds or "")
              + lib.optionalString (cfg.enable && cfg.shortcuts != [ ]) ''
                ${lib.getExe shortcutsSync} ${shortcutsJson} || true
              '';
          });
        })
      ];
    }
    (mkIf cfg.enable {
      environment = {
        systemPackages = with pkgs; lib.optionals maximal [ steamtinkerlaunch ];
      };

      hardware.steam-hardware.enable = true;

      programs.steam = {
        # Steam/Proton documentation
        # See: https://github.com/ValveSoftware/Proton
        enable = true;
        extest.enable = true;
        localNetworkGameTransfers.openFirewall = true;
        protontricks.enable = lib.mkDefault maximal;
        remotePlay.openFirewall = true;

        extraCompatPackages = lib.optionals maximal [ pkgs.proton-ge-bin ];
      };
    })
  ];
}
