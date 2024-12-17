{
  description = "Hello World in .NET";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        projectFile = "./HelloWorld/HelloWorld.fsproj";
        testProjectFile = "./HelloWorld.Test/HelloWorld.Test.fsproj";
        pname = "dotnet-helloworld";
        dotnet-sdk = pkgs.dotnet-sdk_7;
        dotnet-runtime = pkgs.dotnetCorePackages.runtime_7_0;
        version = "0.0.1";
        dotnetSixTool =
          toolName: toolVersion: sha256:
          pkgs.stdenvNoCC.mkDerivation rec {
            name = toolName;
            version = toolVersion;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            src = pkgs.fetchNuGet {
              pname = name;
              inherit version sha256;
              installPhase = ''mkdir -p $out/bin && cp -r tools/net6.0/any/* $out/bin'';
            };
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/lib"
              cp -r ./bin/* "$out/lib"
              makeWrapper "${dotnet-runtime}/bin/dotnet" "$out/bin/${name}" --add-flags "$out/lib/${name}.dll"
              runHook postInstall
            '';
          };
      in
      {
        packages = {
          fantomas = dotnetSixTool "fantomas" "5.1.5" "sha256-qzIs6JiZV9uHUS0asrgWLAbaKJsNtr5h01fJxmOR2Mc=";
          fetchDeps =
            let
              runtimeIds = map (
                system: pkgs.dotnetCorePackages.systemToDotnetRid system
              ) dotnet-sdk.meta.platforms;
            in
            pkgs.writeShellScriptBin "fetch-${pname}-deps" (
              builtins.readFile (
                pkgs.substituteAll {
                  src = ./nix/fetchDeps.sh;
                  inherit pname;
                  inherit (dotnet-sdk) packages;
                  binPath = pkgs.lib.makeBinPath [
                    pkgs.coreutils
                    dotnet-sdk
                    (pkgs.nuget-to-nix.override { inherit dotnet-sdk; })
                  ];
                  projectFiles = toString (pkgs.lib.toList projectFile);
                  testProjectFiles = toString (pkgs.lib.toList testProjectFile);
                  rids = pkgs.lib.concatStringsSep "\" \"" runtimeIds;
                  storeSrc = pkgs.srcOnly {
                    src = ./.;
                    inherit pname version;
                  };
                }
              )
            );
          default = pkgs.buildDotnetModule {
            pname = "HelloWorld";
            inherit
              version
              dotnet-sdk
              dotnet-runtime
              projectFile
              ;
            src = ./.;
            nugetDeps = ./nix/deps.nix;
            doCheck = true;
          };
        };
        devShells = {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.dotnet-sdk_7
              pkgs.git
              pkgs.alejandra
              pkgs.nodePackages.markdown-link-check
            ];
          };
        };
      }
    );
}
