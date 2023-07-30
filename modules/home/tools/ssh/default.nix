{ lib
, config
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.khanelinix.tools.ssh;
in
{
  options.khanelinix.tools.ssh = {
    enable = mkEnableOption "SSH";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      extraConfig = ''
        Host *
          HostKeyAlgorithms +ssh-rsa
      '';
    };
  };
}
