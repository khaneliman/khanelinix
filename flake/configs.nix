{
  inputs,
  lib,
  self,
  ...
}:
let
  # Helper to get all nixos system configs
  getNixosConfigurations =
    system: dir:
    let
      systemDirs = lib.attrNames (builtins.readDir dir);
      # Filter out non-standard directories
      filteredDirs = builtins.filter (
        name: !(lib.hasPrefix "x86_64-install" name) && !(lib.hasPrefix "x86_64-iso" name)
      ) systemDirs;
      makeNixosSystem =
        name:
        let
          systemPath = "${dir}/${name}";
        in
        lib.nixosSystem {
          inherit system;
          lib = lib.extend (
            _final: _prev: {
              inherit (self.lib) khanelinix;
            }
          );
          specialArgs = {
            inherit inputs self;
            lib = lib.extend (
              _final: _prev: {
                inherit (self.lib) khanelinix;
              }
            );
            namespace = "khanelinix";
            khanelinix-lib = self.lib.khanelinix;
          };
          modules = [
            systemPath
            # Import all khanelinix modules
            ../modules/nixos
            inputs.disko.nixosModules.disko
            inputs.home-manager.nixosModules.home-manager
            inputs.lanzaboote.nixosModules.lanzaboote
            inputs.nix-flatpak.nixosModules.nix-flatpak
            inputs.sops-nix.nixosModules.sops
            inputs.stylix.nixosModules.stylix
          ];
        };
    in
    lib.listToAttrs (
      map (name: {
        inherit name;
        value = makeNixosSystem name;
      }) filteredDirs
    );

  # Helper to get all darwin system configs
  getDarwinConfigurations =
    system: dir:
    let
      systemDirs = lib.attrNames (builtins.readDir dir);
      makeDarwinSystem =
        name:
        let
          systemPath = "${dir}/${name}";
        in
        inputs.darwin.lib.darwinSystem {
          inherit system;
          lib = lib.extend (
            _final: _prev: {
              inherit (self.lib) khanelinix;
            }
          );
          specialArgs = {
            inherit inputs self;
            lib = lib.extend (
              _final: _prev: {
                inherit (self.lib) khanelinix;
              }
            );
            namespace = "khanelinix";
            khanelinix-lib = self.lib.khanelinix;
          };
          modules = [
            systemPath
            # Import all khanelinix modules
            ../modules/darwin
            inputs.nix-rosetta-builder.darwinModules.default
            inputs.sops-nix.darwinModules.sops
            inputs.stylix.darwinModules.stylix
          ];
        };
    in
    lib.listToAttrs (
      map (name: {
        inherit name;
        value = makeDarwinSystem name;
      }) systemDirs
    );

  # Helper to get all home configurations
  getHomeConfigurations =
    dir:
    let
      systemDirs = lib.attrNames (builtins.readDir dir);
      getHomeConfigsForSystem =
        system:
        let
          systemPath = "${dir}/${system}";
          homeDirs = lib.attrNames (builtins.readDir systemPath);
          makeHomeConfig =
            name:
            let
              homePath = "${systemPath}/${name}";
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs {
                inherit system;
                overlays = lib.attrValues self.overlays;
                config.allowUnfree = true;
              };
              lib = lib.extend (
                _final: _prev: {
                  inherit (self.lib) khanelinix;
                }
              );
              extraSpecialArgs = {
                inherit
                  inputs
                  self
                  system
                  ;
                lib = lib.extend (
                  _final: _prev: {
                    inherit (self.lib) khanelinix;
                  }
                );
                namespace = "khanelinix";
                khanelinix-lib = self.lib.khanelinix;
              };
              modules = [
                homePath
                # Import all khanelinix modules
                ../modules/home
                inputs.catppuccin.homeModules.catppuccin
                inputs.hypr-socket-watch.homeManagerModules.default
                inputs.nix-index-database.hmModules.nix-index
                inputs.sops-nix.homeManagerModules.sops
              ];
            };
        in
        lib.listToAttrs (
          map (name: {
            inherit name;
            value = makeHomeConfig name;
          }) homeDirs
        );
    in
    lib.foldl (acc: system: acc // (getHomeConfigsForSystem system)) { } systemDirs;
in
{
  flake = {
    nixosConfigurations =
      getNixosConfigurations "x86_64-linux" ../systems/x86_64-linux
      // getNixosConfigurations "aarch64-linux" ../systems/aarch64-linux;
    darwinConfigurations = getDarwinConfigurations "aarch64-darwin" ../systems/aarch64-darwin;
    homeConfigurations = getHomeConfigurations ../homes;

    # Module outputs - simplified approach
    nixosModules = { };
    darwinModules = { };
    homeModules = { };

    # Templates
    templates =
      let
        templateDirs = builtins.readDir ../templates;
        makeTemplate = name: _: {
          path = ../templates + "/${name}";
          description =
            if name == "angular" then
              "Angular template"
            else if name == "c" then
              "C flake template."
            else if name == "container" then
              "Container template"
            else if name == "cpp" then
              "CPP flake template"
            else if name == "dotnetf" then
              "Dotnet FSharp template"
            else if name == "flake-compat" then
              "Flake-compat shell and default files."
            else if name == "go" then
              "Go template"
            else if name == "node" then
              "Node template"
            else if name == "python" then
              "Python template"
            else if name == "rust" then
              "Rust template"
            else if name == "rust-web-server" then
              "Rust web server template"
            else if name == "snowfall" then
              "Snowfall-lib template"
            else
              "${name} template";
        };
      in
      lib.mapAttrs makeTemplate templateDirs;

    # Deploy support (if needed)
    # deploy = khanelinix-lib.deploy.mkDeploy { inherit self inputs; };
  };
}
