{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe'
    types
    mkIf
    foldl
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.terminal.tools.ssh;

  user = config.users.users.${config.khanelinix.user.name};
  user-id = builtins.toString user.uid;

  other-hosts = lib.filterAttrs (_key: host: (host.config.khanelinix.user.name or null) != null) (
    (inputs.self.nixosConfigurations or { }) // (inputs.self.darwinConfigurations or { })
  );

  authorizedKeys = [
    # `khanelinix`
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuMXeT21L3wnxnuzl0rKuE5+8inPSi8ca/Y3ll4s9pC"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEilFPAgSUwW3N7PTvdTqjaV2MD3cY2oZGKdaS7ndKB"
    # `khanelimac`
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAZIwy7nkz8CZYR/ZTSNr+7lRBW2AYy1jw06b44zaID"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBG8l3jQ2EPLU+BlgtaQZpr4xr97n2buTLAZTxKHSsD"
    # `bruddynix`
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeLt5cnRnKeil39Ds+CimMJQq/5dln32YqQ+EfYSCvc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqCiZgjOmhsBTAFD0LbuwpfeuCnwXwMl2wByxC1UiRt"
  ];
in
{
  options.khanelinix.programs.terminal.tools.ssh = with types; {
    enable = lib.mkEnableOption "ssh support";
    authorizedKeys = mkOpt (listOf str) authorizedKeys "The public keys to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks =
        let
          other-hosts-config = lib.foldl' (
            acc: name:
            let
              remote = other-hosts.${name};
              remote-user-name = remote.config.khanelinix.user.name;
              remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;
            in
            acc
            // {
              ${name} = {
                hostname = "${name}.local";
                user = remote-user-name;
                forwardAgent = true;
                inherit (cfg) port;
                remoteForwards =
                  lib.optionals (config.services.gpg-agent.enable && remote.config.services.gpg-agent.enable)
                    [
                      "/run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra"
                      "/run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh"
                    ];
              };
            }
          ) { } (builtins.attrNames other-hosts);
        in
        {
          "*" = {
            addKeysToAgent = "yes";
            forwardAgent = true;
          };
        }
        // other-hosts-config;

      extraConfig = ''
        StreamLocalBindUnlink yes
        ConnectTimeout 5
      ''
      + lib.optionalString (cfg.extraConfig != "") cfg.extraConfig;
    };

    home = {
      shellAliases =
        foldl (aliases: system: aliases // { "ssh-${system}" = "ssh ${system} -t tmux a"; })
          {
            ssh-list-perm-user = ''find ~/.ssh -exec stat -c "%a %n" {} \;'';

            ssh-perm-user = lib.concatStrings [
              ''${getExe' pkgs.findutils "find"} ~/.ssh -type f -exec chmod 600 {} \;;''
              ''${getExe' pkgs.findutils "find"} ~/.ssh -type d -exec chmod 700 {} \;;''
              ''${getExe' pkgs.findutils "find"} ~/.ssh -type f -name "*.pub" -exec chmod 644 {} \;''
            ];

            ssh-list-perm-system = ''sudo find /etc/ssh -exec stat -c "%a %n" {} \;'';

            ssh-perm-system = lib.concatStrings [
              ''sudo ${getExe' pkgs.findutils "find"} /etc/ssh -type f -exec chmod 600 {} \;;''
              ''sudo ${getExe' pkgs.findutils "find"} /etc/ssh -type d -exec chmod 700 {} \;;''
              ''sudo ${getExe' pkgs.findutils "find"} /etc/ssh -type f -name "*.pub" -exec chmod 644 {} \;''
            ];
          }
          (builtins.attrNames other-hosts);

      file = {
        ".ssh/authorized_keys".text = builtins.concatStringsSep "\n" cfg.authorizedKeys;
      };
    };
  };
}
