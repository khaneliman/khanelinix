{ config, lib }:
let
  directHosts = lib.filterAttrs (
    name: entry:
    let
      host = entry.data;
    in
    host.header == "Host ${name}"
    && builtins.match "[A-Za-z0-9._-]+( [A-Za-z0-9._-]+)*" name != null
    && host ? HostName
    && host ? User
    && !(host ? ProxyJump || host ? ProxyCommand || host ? IdentityAgent)
  ) config.programs.ssh.settings;
in
lib.optionalAttrs config.programs.ssh.enable {
  # Use direct host metadata and SSH_AUTH_SOCK, not OpenSSH match/proxy semantics.
  sftp = lib.mapAttrs' (
    name: entry:
    lib.nameValuePair (builtins.head (lib.splitString " " name)) {
      host = entry.data.HostName;
      user = entry.data.User;
      port = entry.data.Port or 22;
    }
  ) directHosts;
}
