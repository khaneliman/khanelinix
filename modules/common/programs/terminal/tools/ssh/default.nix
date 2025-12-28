{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.terminal.tools.ssh;

  user = config.users.users.${config.khanelinix.user.name};
  user-id = toString user.uid;

  hosts = import ./hosts.nix;

  # Filter out the current host from the SSH configuration
  other-hosts = lib.filterAttrs (name: _: name != config.networking.hostName) hosts;

  other-hosts-config = lib.concatMapStringsSep "\n" (
    name:
    let
      remote = other-hosts.${name};
      remote-user-name = remote.username;
      # Use system-specific default UIDs: macOS starts at 501, Linux at 1000
      remote-user-id = if remote.system == "darwin" then "501" else "1000";

      forward-gpg =
        lib.optionalString (config.programs.gnupg.agent.enable && remote.gpgAgent)
          "  RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra\n  RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh";
      port-expr = lib.optionalString (remote.system == "nixos") "  Port ${toString cfg.port}";
    in
    lib.concatStringsSep "\n" (
      lib.filter (x: x != "") [
        "Host ${name}"
        "  Hostname ${remote.hostname}"
        "  User ${remote-user-name}"
        "  ForwardAgent yes"
        "  ConnectTimeout 10"
        port-expr
        forward-gpg
      ]
    )
  ) (builtins.attrNames other-hosts);
in
{
  options.khanelinix.programs.terminal.tools.ssh = {
    enable = lib.mkEnableOption "ssh support";
    extraConfig = mkOpt lib.types.str "" "Extra configuration to apply.";
    port = mkOpt lib.types.port 2222 "The port to listen on (in addition to 22).";
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      extraConfig = ''
        ${other-hosts-config}${
          lib.optionalString (cfg.extraConfig != "") ''

            ${cfg.extraConfig}''
        }
      '';

      knownHosts = lib.mapAttrs (_: lib.mkForce) (
        {
          # Ship GitHub/GitLab/SourceHut host keys to avoid “man in the middle” attacks
          github-rsa = {
            hostNames = [ "github.com" ];
            publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==";
          };

          github-ed25519 = {
            hostNames = [ "github.com" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
          };

          gitlab-rsa = {
            hostNames = [ "gitlab.com" ];
            publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9";
          };

          gitlab-ed25519 = {
            hostNames = [ "gitlab.com" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
          };

          sourcehut-rsa = {
            hostNames = [ "git.sr.ht" ];
            publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZ+l/lvYmaeOAPeijHL8d4794Am0MOvmXPyvHTtrqvgmvCJB8pen/qkQX2S1fgl9VkMGSNxbp7NF7HmKgs5ajTGV9mB5A5zq+161lcp5+f1qmn3Dp1MWKp/AzejWXKW+dwPBd3kkudDBA1fa3uK6g1gK5nLw3qcuv/V4emX9zv3P2ZNlq9XRvBxGY2KzaCyCXVkL48RVTTJJnYbVdRuq8/jQkDRA8lHvGvKI+jqnljmZi2aIrK9OGT2gkCtfyTw2GvNDV6aZ0bEza7nDLU/I+xmByAOO79R1Uk4EYCvSc1WXDZqhiuO2sZRmVxa0pQSBDn1DB3rpvqPYW+UvKB3SOz";
          };

          sourcehut-ed25519 = {
            hostNames = [ "git.sr.ht" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZvRd4EtM7R+IHVMWmDkVU3VLQTSwQDSAvW0t2Tkj60";
          };

          # Community builders
          "aarch64-build-box.nix-community.org" = {
            hostNames = [ "aarch64-build-box.nix-community.org" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9uyfhyli+BRtk64y+niqtb+sKquRGGZ87f4YRc8EE1";
          };
          "darwin-build-box.nix-community.org" = {
            hostNames = [ "darwin-build-box.nix-community.org" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKMHhlcn7fUpUuiOFeIhDqBzBNFsbNqq+NpzuGX3e6zv";
          };
          "build-box.nix-community.org" = {
            hostNames = [ "build-box.nix-community.org" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElIQ54qAy7Dh63rBudYKdbzJHrrbrrMXLYl7Pkmk88H";
          };
        }
        // lib.mapAttrs (_: host: {
          hostNames = [ host.hostname ];
          inherit (host) publicKey;
        }) (lib.filterAttrs (_: host: host ? publicKey) hosts)
        //
          lib.mapAttrs
            (_name: host: {
              hostNames = [ host.hostname ];
              publicKey = host.userPublicKey;
            })
            (
              lib.mapAttrs' (name: host: {
                name = "${host.username}@${name}";
                value = host;
              }) (lib.filterAttrs (_: host: host ? userPublicKey) hosts)
            )
      );
    };

    khanelinix = {
      home.extraOptions = {
        programs.zsh.shellAliases = lib.foldl (
          aliases: system: aliases // { "ssh-${system}" = "ssh ${system} -t tmux a"; }
        ) { } (builtins.attrNames other-hosts);
      };
    };

  };
}
