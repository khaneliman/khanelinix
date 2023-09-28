{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf getExe;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.desktop.addons.eww;

  dependencies = with pkgs; [
    bash
    blueberry
    bluez
    coreutils
    dbus
    findutils
    gawk
    gnome.gnome-control-center
    gnused
    gojq
    imagemagick
    jaq
    jc
    libnotify
    light
    networkmanager
    pavucontrol
    playerctl
    procps
    pulseaudio
    ripgrep
    socat
    udev
    upower
    util-linux
    wget
    wireplumber
    wlogout
  ];

  reload_script = pkgs.writeShellScript "reload_eww" ''
    windows=$(eww windows | rg '\*' | tr -d '*')

    systemctl --user restart eww.service

    echo $windows | while read -r w; do
      eww open $w
    done
  '';
in
{
  options.khanelinix.desktop.addons.eww = with types; {
    enable = mkBoolOpt false "Whether to enable eww in the desktop environment.";
    autoReload = mkBoolOpt false "Whether to restart the eww daemon and windows on change.";
    colors = lib.mkOption {
      type = with lib.types; nullOr lines;
      default = null;
      defaultText = lib.literalExpression "null";
      description = ''
        SCSS file with colors defined in the same way as Catppuccin colors are,
        to be used by eww.

        Defaults to Catppuccin Mocha.
      '';
    };
    package = mkOpt package pkgs.eww "The Eww package to install";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = dependencies;

    fonts.fonts = with pkgs; [
      jost
      material-design-icons
      material-icons
      material-symbols
    ];

    khanelinix.home = {
      extraOptions = {
        home.packages = [
          cfg.package
        ];

        # remove nix files
        xdg.configFile."eww" = {
          source = lib.cleanSourceWith {
            filter = name: _type:
              let
                baseName = baseNameOf (toString name);
              in
                !(lib.hasSuffix ".nix" baseName);
            src = lib.cleanSource ./.;
          };

          recursive = true;

          onChange =
            if cfg.autoReload
            then reload_script.outPath
            else "";
        };

        systemd.user.services.eww = {
          Install.WantedBy = [ "graphical-session.target" ];

          Service = {
            Environment = "PATH=/run/wrappers/bin:${lib.makeBinPath dependencies}";
            ExecStart = "${getExe cfg.package} daemon --no-daemonize";
            Restart = "on-failure";
          };

          Unit = {
            Description = "Eww Daemon";
            # not yet implemented
            # PartOf = ["tray.target"];
            PartOf = [ "graphical-session.target" ];
          };
        };
      };
    };
  };
}
