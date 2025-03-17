{
  config,
  lib,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    foldl
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.programs.terminal.tools.ssh;

  user = config.users.users.${config.${namespace}.user.name};
  user-id = builtins.toString user.uid;

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

  other-hosts = lib.filterAttrs (_key: host: (host.config.${namespace}.user.name or null) != null) (
    (inputs.self.nixosConfigurations or { }) // (inputs.self.darwinConfigurations or { })
  );

  other-hosts-config = lib.foldl' (
    acc: name:
    let
      remote = other-hosts.${name};
      remote-user-name = remote.config.${namespace}.user.name;
      remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;
    in
    acc
    // {
      ${name} = {
        hostname = "${name}.local";
        user = remote-user-name;
        forwardAgent = true;
        port = lib.mkIf (builtins.hasAttr name inputs.self.nixosConfigurations) cfg.port;
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
  options.${namespace}.programs.terminal.tools.ssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure ssh support.";
    authorizedKeys = mkOpt (listOf str) authorizedKeys "The public keys to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      addKeysToAgent = "yes";
      matchBlocks = other-hosts-config;

      extraConfig =
        ''
          StreamLocalBindUnlink yes
        ''
        + lib.optionalString (cfg.extraConfig != "") cfg.extraConfig;
    };

    home = {
      shellAliases = foldl (
        aliases: system: aliases // { "ssh-${system}" = "ssh ${system} -t tmux a"; }
      ) { } (builtins.attrNames other-hosts);

      file = {
        ".ssh/authorized_keys".text = builtins.concatStringsSep "\n" cfg.authorizedKeys;
      };
    };
  };
}
