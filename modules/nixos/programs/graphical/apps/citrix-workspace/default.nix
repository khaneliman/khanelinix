{
  config,
  getPkgsMaster,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.apps.citrix-workspace;
  pkgsMaster = getPkgsMaster pkgs.stdenv.hostPlatform.system { inherit (pkgs) config; };
  citrixPackage = pkgsMaster.citrix-workspace.override {
    extraPkcs11Modules = [ "${pkgsMaster.opensc}/lib/opensc-pkcs11.so" ];
  };
  udevRules = pkgs.runCommand "citrix-workspace-udev-rules" { } ''
    mkdir -p $out/lib/udev/rules.d
    ln -s ${cfg.package}/lib/udev/rules.d/61-ica-mtch.rules $out/lib/udev/rules.d/
    ${lib.optionalString cfg.usbRedirection.enable ''
      ln -s ${cfg.package}/lib/udev/rules.d/85-ica-usb.rules $out/lib/udev/rules.d/
    ''}
  '';
in
{
  options.khanelinix.programs.graphical.apps.citrix-workspace = {
    enable = lib.mkEnableOption "Citrix Workspace system integration";
    package = lib.mkOption {
      type = lib.types.package;
      default = citrixPackage;
      defaultText = lib.literalExpression "patched pkgsMaster.citrix-workspace with OpenSC";
      description = "Citrix Workspace package to integrate with NixOS.";
    };

    usbRedirection.enable = lib.mkEnableOption "generic Citrix USB redirection";
  };

  config = lib.mkIf cfg.enable {
    khanelinix.home.extraOptions.khanelinix.programs.graphical.apps.citrix-workspace.package =
      cfg.package;

    programs.fuse.enable = true;

    services = {
      pcscd.enable = true;
      udev.packages = [ udevRules ];
    };

    security.wrappers.ctxusb = lib.mkIf cfg.usbRedirection.enable {
      source = "${cfg.package.icaroot}/ctxusb.real";
      owner = "root";
      group = "root";
      permissions = "a+rx";
      setuid = true;
    };

    systemd.services.ctxusbd = lib.mkIf cfg.usbRedirection.enable {
      description = "Citrix USB Service";
      wantedBy = [ "multi-user.target" ];
      requires = [ "systemd-udevd.service" ];
      after = [ "systemd-udevd.service" ];

      unitConfig.ConditionPathIsDirectory = "/dev/bus/usb";

      serviceConfig = {
        Type = "forking";
        ExecStart = "${cfg.package.icaroot}/ctxusbd";
        Restart = "always";
        TimeoutSec = 300;
        RuntimeDirectory = "ctxusbd";
        RuntimeDirectoryMode = "0700";
        SyslogIdentifier = "ctxusbd";
        # ctxusbd dlopen's libcap at runtime; autoPatchelf only fixes
        # static NEEDED entries so the library is not in the rpath.
        Environment = "LD_LIBRARY_PATH=${lib.getLib pkgsMaster.libcap}/lib";
      };
    };
  };
}
