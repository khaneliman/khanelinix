let
  hosts = import ./fleet-ssh-hosts.nix;
  keyedHosts = builtins.filter (host: host ? userPublicKey) (builtins.attrValues hosts);
in
map (host: host.userPublicKey) keyedHosts
++ [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1MjYs1zQ6dxFyNwUTR/1K0QI65nuJ6h1xINWnQEUdy hermes-agent@austinserver"
]
