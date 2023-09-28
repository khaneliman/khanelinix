{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf getExe';
  inherit (lib.internal) mkBoolOpt mkOpt stringAfter;

  cfg = config.khanelinix.display-managers.sddm;
in
{
  options.khanelinix.display-managers.sddm = with types; {
    enable = mkBoolOpt false "Whether or not to enable sddm.";
    defaultSession = mkOpt (nullOr types.str) null "The default session to use.";
  };

  config =
    mkIf cfg.enable
      {
        environment.systemPackages = with pkgs; [
          catppuccin-sddm-corners
          sddm
        ];

        services.xserver = {
          enable = true;

          displayManager = {
            inherit (cfg) defaultSession;

            sddm = {
              inherit (cfg) enable;
              theme = "catppuccin-sddm-corners";

              settings = {
                General = {
                  GreeterEnvironment = "QT_PLUGIN_PATH=${pkgs.plasma5Packages.layer-shell-qt}/${pkgs.plasma5Packages.qtbase.qtPluginPrefix},QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
                  DisplayServer = "wayland";
                  InputMethod = "";
                };
                Wayland.CompositorCommand = "${getExe' pkgs.kwin "kwin_wayland"} --no-global-shortcuts --no-lockscreen --locale1";
              };
            };
          };

          libinput.enable = true;
        };

        system.activationScripts.postInstallSddm = stringAfter [ "users" ] ''
          echo "Setting sddm permissions for user icon"
          ${getExe' pkgs.acl "setfacl"} -m u:sddm:x /home/${config.khanelinix.user.name}
          ${getExe' pkgs.acl "setfacl"} -m u:sddm:r /home/${config.khanelinix.user.name}/.face.icon || true
        '';
      };
}
