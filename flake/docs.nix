{ inputs, lib, ... }:
{

  flake = {
    nixosModules.default = ../modules/nixos;
    darwinModules.default = ../modules/darwin;
    homeManagerModules.default = ../modules/home;
  };

  perSystem =
    { config, pkgs, ... }:
    let
      inherit (inputs.self.lib.system) common;
      extendedLib = inputs.nixpkgs.lib.extend inputs.self.lib.overlay;
      nixpkgsConfig = common.mkNixpkgsConfig inputs.self;
      mkOptionsDoc =
        eval:
        pkgs.nixosOptionsDoc {
          options = lib.filterAttrs (name: _: name == "khanelinix") eval.options;
          warningsAreErrors = false;
        };
      pkgsForDocs = import inputs.nixpkgs (
        nixpkgsConfig
        // {
          inherit (pkgs.stdenv.hostPlatform) system;
          overlays = nixpkgsConfig.overlays ++ lib.optional (inputs ? niri) inputs.niri.overlays.niri;
        }
      );

      # NixOS Options Evaluation
      nixosOptions =
        let
          eval = inputs.nixpkgs.lib.nixosSystem {
            inherit (pkgs.stdenv.hostPlatform) system;
            modules = [
              (_: {
                documentation.nixos.options.warningsAreErrors = false;
              })
              (_: {
                nixpkgs.pkgs = pkgsForDocs;
              })
              inputs.home-manager.nixosModules.home-manager
              inputs.lanzaboote.nixosModules.lanzaboote
              inputs.sops-nix.nixosModules.sops
              inputs.disko.nixosModules.disko
              inputs.stylix.nixosModules.stylix
              inputs.catppuccin.nixosModules.catppuccin
              inputs.nix-index-database.nixosModules.nix-index
              inputs.nix-flatpak.nixosModules.nix-flatpak
            ]
            ++ inputs.self.lib.file.importModulesRecursive ../modules/nixos;
            specialArgs = {
              inherit inputs;
              lib = extendedLib;
              virtual = false;
            };
          };
        in
        mkOptionsDoc eval;

      # Darwin Options Evaluation
      darwinOptions =
        let
          eval = inputs.nix-darwin.lib.darwinSystem {
            inherit (pkgs.stdenv.hostPlatform) system;
            modules = [
              (_: {
                documentation.doc.enable = false;
              })
              (_: {
                nixpkgs.pkgs = pkgsForDocs;
              })
              inputs.home-manager.darwinModules.home-manager
              inputs.nix-index-database.darwinModules.nix-index
              inputs.stylix.darwinModules.stylix
              inputs.sops-nix.darwinModules.sops
              inputs.nix-rosetta-builder.darwinModules.default
            ]
            ++ inputs.self.lib.file.importModulesRecursive ../modules/darwin;
            specialArgs = {
              inherit inputs;
              lib = extendedLib;
            };
          };
        in
        mkOptionsDoc eval;

      # Home Manager Options Evaluation
      hmOptions =
        let
          eval = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = pkgsForDocs;
            check = false;
            modules = [
              (_: {
                nixpkgs.pkgs = pkgsForDocs;
                nixpkgs.overlays = [ ];
                programs.home-manager.enable = true;
                home = {
                  stateVersion = "24.05";
                  username = "docs";
                  homeDirectory = "/home/docs";
                };
                stylix.overlays.enable = false;
                targets.darwin.linkApps.enable = false;
              })
              inputs.sops-nix.homeManagerModules.sops
              inputs.nix-index-database.homeModules.nix-index
              inputs.nix-flatpak.homeManagerModules.nix-flatpak
              inputs.catppuccin.homeModules.catppuccin
            ]
            ++ inputs.self.lib.file.importModulesRecursive ../modules/home;
            extraSpecialArgs = {
              inherit inputs;
              lib = extendedLib;
              hostname = "docs";
              username = "docs";
            };
          };
        in
        mkOptionsDoc eval;
    in
    {
      packages.docs-html = pkgs.stdenvNoCC.mkDerivation {
        name = "docs-html";
        src = ../docs;
        nativeBuildInputs = [
          pkgs.mdbook
          pkgs.python3
        ];
        buildPhase = ''
          runHook preBuild

          # Create option directories
          mkdir -p options/nixos options/darwin options/home-manager

          # Copy generated markdown files
          cp ${nixosOptions.optionsCommonMark} options/nixos.md
          cp ${darwinOptions.optionsCommonMark} options/darwin.md
          cp ${hmOptions.optionsCommonMark} options/home-manager.md

          # Split options and update SUMMARY.md
          python3 scripts/split-options.py options/nixos.md options/nixos "{{NIXOS_OPTIONS}}"
          python3 scripts/split-options.py options/darwin.md options/darwin "{{DARWIN_OPTIONS}}"
          python3 scripts/split-options.py options/home-manager.md options/home-manager "{{HM_OPTIONS}}"

          # Build the book
          mdbook build --dest-dir $out .

          # Copy raw options for reference
          mkdir -p $out/raw-options
          cp options/nixos.md $out/raw-options/nixos.md
          cp options/darwin.md $out/raw-options/darwin.md
          cp options/home-manager.md $out/raw-options/home-manager.md

          runHook postBuild
        '';
        dontInstall = true;
      };

      apps.docs =
        let
          opener = if pkgs.stdenv.isDarwin then "open" else "xdg-open";
          openDocs = pkgs.writeShellScript "open-docs" ''
            path="${config.packages.docs-html}/index.html"
            if ! ${opener} "$path"; then
              echo "Failed to open docs with ${opener}. Docs are at:"
              echo "$path"
            fi
          '';
        in
        {
          type = "app";
          program = "${openDocs}";
          meta.description = "Open internal docs in browser";
        };

      apps.docs-html = config.apps.docs;
    };
}
