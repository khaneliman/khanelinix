{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.tools.python;
in
{
  options.khanelinix.tools.python = {
    enable = mkBoolOpt false "Whether or not to enable python.";
  };

  config =
    mkIf cfg.enable
      {
        environment.systemPackages = with pkgs; [
          (python311.withPackages (ps:
            with ps; [
              pip
              pyqt5
              qtpy
              requests
            ]))
        ];
      };
}
