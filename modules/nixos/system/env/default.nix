{ lib, ... }:
{
  imports = [
    (lib.modules.importApply (lib.getFile "modules/common/system/env/default.nix") (less: {
      SYSTEMD_PAGERSECURE = "true";
      SYSTEMD_LESS = lib.concatStringsSep " " [
        less
        "--quit-if-one-screen"
        "--chop-long-lines"
        "--no-init" # Keep content after quit.
      ];
    }))
  ];
}
