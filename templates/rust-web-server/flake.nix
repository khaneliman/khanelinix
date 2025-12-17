{
  description = "A Rust web server including a NixOS module";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.import-cargo.url = "github:edolstra/import-cargo";

  outputs =
    {
      self,
      nixpkgs,
      import-cargo,
    }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = "${builtins.substring 0 8 lastModifiedDate}-${self.shortRev or "dirty"}";

      # System types to support.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forEachSystem (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        }
      );
    in
    {

      # A Nixpkgs overlay.
      overlay = final: _prev: {

        rust-web-server =
          with final;
          final.callPackage (
            {
              inShell ? false,
            }:
            stdenv.mkDerivation rec {
              name = "rust-web-server-${version}";

              # In 'nix develop', we don't need a copy of the source tree
              # in the Nix store.
              src = if inShell then null else ./.;

              buildInputs = [
                rustc
                cargo
              ]
              ++ (
                if inShell then
                  [
                    # In 'nix develop', provide some developer tools.
                    rustfmt
                    clippy
                  ]
                else
                  [
                    (import-cargo.builders.importCargo {
                      lockFile = ./Cargo.lock;
                      inherit pkgs;
                    }).cargoHome
                  ]
              );

              target = "--release";

              buildPhase = "cargo build ${target} --frozen --offline";

              doCheck = true;

              checkPhase = "cargo test ${target} --frozen --offline";

              installPhase = ''
                mkdir -p $out
                cargo install --frozen --offline --path . --root $out
                rm $out/.crates.toml
              '';
            }
          ) { };
      };

      # Provide some binary packages for selected system types.
      packages = forEachSystem (system: {
        inherit (nixpkgsFor.${system}) rust-web-server;
      });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forEachSystem (system: self.packages.${system}.rust-web-server);

      # Provide a 'nix develop' environment for interactive hacking.
      devShell = forEachSystem (
        system: self.packages.${system}.rust-web-server.override { inShell = true; }
      );

      # A NixOS module.
      nixosModules.rust-web-server =
        { pkgs, ... }:
        {
          nixpkgs.overlays = [ self.overlay ];

          systemd.services.rust-web-server = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig.ExecStart = "${pkgs.rust-web-server}/bin/rust-web-server";
          };
        };

      # Tests run by 'nix flake check' and by Hydra.
      checks = forEachSystem (
        system:
        with nixpkgsFor.${system};

        {
          inherit (self.packages.${system}) rust-web-server;

          # A VM test of the NixOS module.
          vmTest =
            with import (nixpkgs + "/nixos/lib/testing-python.nix") { inherit system; };

            makeTest {
              nodes = {
                client =
                  { ... }:
                  {
                    imports = [ self.nixosModules.rust-web-server ];
                  };
              };

              testScript = /* Python */ ''
                start_all()
                client.wait_for_unit("multi-user.target")
                assert "Hello Nixers" in client.wait_until_succeeds("curl --fail http://localhost:8080/")
              '';
            };
        }
      );
    };
}
