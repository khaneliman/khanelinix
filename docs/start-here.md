# Start Here

KhaneliNix is a personal fleet with selected reusable modules and packages. Do
not switch to an existing fleet output on a new machine. Those outputs carry
hardware, identities, credentials, network trust, and workloads for their named
hosts. Start with a neutral consumer and build it before considering activation.

## Neutral first host and home

The executable examples in `tests/consumers/default.nix` use the public module
exports with the stock NixOS, nix-darwin, and Home Manager constructors. They do
not use the internal fleet constructors or require personal credentials.

Create a `flake.nix` using your local checkout or fork as the input. Replace the
absolute path below; a published fork can use its pinned Git URL instead.

```nix
{
  inputs.khanelinix.url = "path:/absolute/path/to/khanelinix";
  outputs = { khanelinix, ... }:
    let
      examples = import (khanelinix.outPath + "/tests/consumers") {
        flake = khanelinix;
      };
    in {
      nixosConfigurations.first-host = examples.nixos;
      darwinConfigurations.first-host = examples.darwin;
      homeConfigurations."example@first-host" = examples.home; # examples.homeDarwin on Darwin
    };
}
```

Pin that input with `nix flake lock`. On the matching platform, build without
activating:

```bash
nix build .#nixosConfigurations.first-host.config.system.build.toplevel --no-link
nix build .#darwinConfigurations.first-host.system --no-link
nix build '.#homeConfigurations."example@first-host".activationPackage' --no-link
```

The NixOS example uses a temporary root filesystem and no bootloader. It is an
evaluation/build example, not a disk installation recipe. Before using a real
host, replace it with hardware detection, filesystems, and an appropriate
bootloader. Replace the example username, home directory, Git identity, and
state versions when creating new configurations. Existing state versions are
migration state and must not be bumped casually.

The Darwin home in the examples uses `/Users/example`, not `/home/example`.
Standalone Home Manager owns only home-level state. It cannot install system
services or a Darwin container VM backend for you.

## Public composition contract

Use `nixosModules.default`, `darwinModules.default`, or
`homeManagerModules.default` (`homeModules.default` is an alias). Supply
`lib.system.moduleArgs { system; hostname; username; }` as `specialArgs` for a
system or `extraSpecialArgs` for a home. This provides the extended library,
locked upstream inputs, auxiliary package-set functions, and repository helpers.
Do not replace `inputs.self` with your consumer flake: repository assets belong
to the input; your host configuration belongs to your own flake.

System aggregates provision their upstream modules, package policy, all fleet
package overlays, and integrated Home Manager composition. They do not discover
homes or choose a personal account. Define the user and its home explicitly. For
standalone Home Manager, import a package set with
`lib.system.common.mkNixpkgsConfig khanelinix`, pass it as `pkgs`, and also pass
that same set in `extraSpecialArgs.pkgs`. This keeps package ownership outside
Home Manager and avoids a pinned Stylix/Home Manager overlay-library recursion.
The executable examples show the complete composition, not just entry paths.

Integrated homes receive their own account name, not the primary system user's
name. If you disable Stylix's automatic Home Manager import, the aggregate still
supplies the home module so an explicitly enabled home theme remains usable.

The aggregate package policy allows unfree packages and a specific insecure
package allowlist required by fleet workloads. Review that policy before broader
use. Auxiliary master/unstable package functions deliberately omit overlays. Raw
leaf modules are reference building blocks: importing one alone does not
provision its library, upstream options, or package dependencies.

For independent package use, select `packages.<system>.<name>`. To add local
packages to an existing package set, use `overlays.default`; it supplies only
`pkgs.khanelinix`, not the full fleet overlay stack. Named overlays are separate
opt-ins. Packages and overlays do not require fleet accounts or activation.

With Nix management and the home-network environment enabled, an explicit
`khanelinix.nix.localCaches` map converts cache names to
`http://<name>.local:5020` and supplies their declared public keys. The current
hostname is excluded. An empty map selects no LAN cache; fleet cache values are
not reusable defaults. Without a repository-managed account, Nix management
leaves the upstream or consumer-owned allowed-user policy intact.

## Fork layout and fleet constructors

Actual discovery paths are:

- `systems/x86_64-linux/<host>/default.nix`
- `systems/aarch64-darwin/<host>/default.nix`
- `homes/<system>/<user>@<host>/default.nix`

Discovery uses architecture-qualified identities internally. Duplicate public
host or `user@host` names fail rather than select an architecture silently. The
obsolete ARM VM is explicitly reference-only.

`lib.system.mkSystem`, `mkDarwin`, and `mkHome` are fleet constructors. They
close over this repository's inputs; an inner `inputs` argument does not replace
them. System constructors append a repository host path and discover matching
homes. They import `systems/fleet-defaults.nix` and `systems/fleet-policy.nix`,
which restore the existing fleet identity and trust choices. Named homes import
`homes/identity.nix`, `credentials.nix`, and `fleet-ssh.nix`. A fork must
replace these owning files, not merely rename a host. Use the public consumer
path above when you want selected capabilities without fleet policy.

## Named standalone homes

Each named standalone home reuses its matching system package set and Home
Manager shared modules, uses that system configuration as explicit `osConfig`
and inherits that system's home-level overrides. This supplies WSL,
package-profile, desktop/session, hardware, service, and Darwin backend context.
It does not activate the system or give a standalone home ownership of system
services. Standalone evaluation therefore also depends on the corresponding host
composition, including native Darwin patch realization where applicable. Stylix
is provisioned for both standalone and integrated homes; explicit curated themes
retain cursor ownership. WSL homes use user `nixos` and `/home/nixos`.

The current workstation uses integrated Home Manager activation. Building a
standalone activation package is not permission to run it, switch a standalone
profile, or recreate a Home Manager profile for the live user.

## Support and verification

See [support and verification](support.md) for output coverage, image operation,
verification commands, evidence levels, and outstanding gaps. Package profiles
`core`, `standard`, and `maximal` affect participating payload gates, not every
explicit program selection. A smaller profile does not remove explicit
overrides.

Build the documentation with `nix build .#docs-html`; open the resulting
`result/index.html`, or run `nix run .#docs`.
