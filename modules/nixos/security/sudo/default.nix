{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkForce mkDefault;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.security.sudo;
in
{
  options.${namespace}.security.sudo = {
    enable = mkBoolOpt false "Whether or not to enable sudo.";
  };
  config = mkIf cfg.enable {
    security = {
      sudo = {
        enable = true;

        execWheelOnly = mkForce true;
        wheelNeedsPassword = mkDefault false;

        extraConfig = ''
          Defaults lecture = never # rollback results in sudo lectures after each reboot, it's somewhat useless anyway
          Defaults pwfeedback # password input feedback - makes typed password visible as asterisks
          Defaults env_keep += "EDITOR PATH DISPLAY" # variables that will be passed to the root account
          Defaults timestamp_timeout = 300 # makes sudo ask for password less often
        '';

        extraRules =
          let
            sudoRules = with pkgs; [
              {
                package = coreutils;
                command = "sync";
              }
              {
                package = hdparm;
                command = "hdparm";
              }
              {
                package = nix;
                command = "nix-collect-garbage";
              }
              {
                package = nix;
                command = "nix-store";
              }
              {
                package = nixos-rebuild;
                command = "nixos-rebuild";
              }
              {
                package = nvme-cli;
                command = "nvme";
              }
              {
                package = systemd;
                command = "poweroff";
              }
              {
                package = systemd;
                command = "reboot";
              }
              {
                package = systemd;
                command = "shutdown";
              }
              {
                package = systemd;
                command = "systemctl";
              }
              {
                package = util-linux;
                command = "dmesg";
              }
            ];

            mkSudoRule = rule: {
              command = lib.getExe' rule.package rule.command;
              options = [ "NOPASSWD" ];
            };

            sudoCommands = map mkSudoRule sudoRules;
          in
          [
            {
              groups = [ "wheel" ];
              commands = sudoCommands;
            }
          ];
      };
    };
  };
}
