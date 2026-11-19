let
  hosts = import ./fleet-ssh-hosts.nix;
  keyedHosts = builtins.filter (host: host ? userPublicKey) (builtins.attrValues hosts);
in
map (host: host.userPublicKey) keyedHosts
